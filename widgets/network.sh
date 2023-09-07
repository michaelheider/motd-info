#!/bin/bash
set -euo pipefail

# Print network information.
# All local interafces and IPs, public IPv4 & IPv6, hostname.
# It takes roughly 1s to get both IPv4 and IPv6.
# Run it to see what it looks like.

# config
TIMEOUT=1.0 # seconds to get public IPs, can be decimal. '0' disables the timeout.

TOOL_PATH=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${TOOL_PATH}/colors.sh"

# $1 is the IP version. Must be '4' or '6'.
getPublicIp() {
	# Command needs to be inside if to be able to
	# read return value into variable and read exit status and have `set -2`.
	if answer=$(timeout $TIMEOUT curl https://ip${1}only.me/api/ 2>/dev/null); then
		ip=$(awk -F ',' '{print $2}' <<<"$answer")
	else
		status=$?
		case $status in
		124 | 137)
			# timeout 124: terminated, timeout 137: killed
			ip="${COLOR_INFO}IPv${1} timeout${RESET}"
			;;
		6)
			# curl 6: could not resolve host
			ip="${COLOR_INFO}IPv${1} DNS failed${RESET}"
			;;
		7)
			# curl 7: failed to connect to host
			ip="${COLOR_INFO}IPv${1} conn failed${RESET}"
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

# oublic IPs
publicIp4=$(getPublicIp 4)
publicIp6=$(getPublicIp 6)

# local IPs & interfaces
localIps=$(ip -oneline addr show | awk '{print $1" " $2" "$4}' | cut -c 4- | grep -Ev " fe80:|^lo " || test $? = 1)
localIps=${localIps// /|}

# assemble message (as table)
message="$localIps\n"
message+="pub|$publicIp4\n"
message+="pub|$publicIp6\n"
message+="host|$(uname -n)\n"

# output
echo 'network:'
echo -e "$message" | column -ts'|' | sed 's,^,  ,'
