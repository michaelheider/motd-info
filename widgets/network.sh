#!/bin/bash
set -euo pipefail

# Print network information.
# All local interafces with network IPs, public IPv4 & IPv6, hostname.
# It takes less than 0.05s each to get the public IPv4 and IPv6.
# Run it to see what it looks like.

# config
TIMEOUT=0.5 # seconds. Timeout to get public IPs, can be decimal. 0 disables the timeout.

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

# $1 is the IP version. Must be '4' or '6'.
getPublicIp() {
	# Command needs to be inside if to be able to
	# read return value into variable and read exit status and have `set -2`.

	# IP protocol version. Must be 4 or 6.
	V=$1
	case $V in
	4)
		# use IP to save lookup time & circumvent possible DNS issues
		# resolver1.opendns.com
		RESOLVER='208.67.222.222'
		RECORD=A
		;;
	6)
		# use IP to save lookup time & circumvent possible DNS issues
		# dns.umbrella.com (could also use: resolver1.ipv6-sandbox.opendns.com)
		RESOLVER='2620:119:35::35'
		RECORD=AAAA
		;;
	esac

	# myip.opendns.com: Query A or AAAA for your source address as seen by the resolver
	# NOTE: DNSSEC is not supported for myip.opendns.com (2023-09-10).
	#       The returned record is dynamic, but they could also generate a dynamic signature.
	if ip=$(timeout $TIMEOUT dig -"$V" +short +dnssec 'myip.opendns.com' "$RECORD" "@$RESOLVER" 2>/dev/null); then
		# in case further results are returned, limit to first row
		# this will matter if DNSSEC ever is enabled for myip.opendns.com
		ip=$(head -n1 <<<"$ip")
	else
		status=$?
		case $status in
		124 | 137)
			# timeout 124: terminated, timeout 137: killed
			ip="${COLOR_INFO}IPv$V timeout${RESET}"
			;;
		9)
			# dig 6: no reply from server
			ip="${COLOR_INFO}IPv$V conn failed${RESET}"
			;;
		10)
			# dig 10: internal error
			# (includes could not resolve IP of resolver server if given by domain)
			ip="${COLOR_INFO}IPv$V DNS failed${RESET}"
			;;
		*)
			# should never happen
			echo -e "${COLOR_BAD}network widget: programmer mistake${RESET}" >&2
			exit $status
			;;
		esac
	fi

	echo "$ip"
}

# public IPs
echo "get public IPs..." >&2
publicIp4=$(getPublicIp 4)
publicIp6=$(getPublicIp 6)
echo -e "$LINE_UP$LINE_CLEAR$LINE_UP" >&2 # clear previous message

# local IPs & interfaces
localIps=$(ip -oneline addr show | awk '{print $2" "$4}' | sort -n | grep -Ev " fe80:|^lo " || test $? = 1)
localIps=${localIps// /|}

# assemble message (as table)
message="$localIps\n"
message+="pub|$publicIp4\n"
message+="pub|$publicIp6\n"
message+="host|$(uname -n)\n"

# output
echo 'network:'
echo -e "$message" | column -ts'|' | sed 's,^,  ,'
