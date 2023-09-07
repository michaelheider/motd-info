#!/bin/bash
set -euo pipefail
LANG=en_US.UTF-8

# Print network information.
# All local interafces and IPs, public IPv4 & IPv6, hostname.
# It takes roughly 1s to get both IPv4 and IPv6.
# Run it to see what it looks like.

# config
TIMEOUT=0.5 # seconds to get public IPs, can be decimal. '0' disables the timeout.

toolPath=$(realpath "$(dirname "$0")/../tools")
source "${toolPath}/colors.sh"

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
			ip="${infoColor}timeout${reset}"
			;;
		6)
			# curl 6: could not resolve host
			ip="${infoColor}DNS failed${reset}"
			;;
		7)
			# curl 7: failed to connect to host
			ip="${infoColor}conn failed${reset}"
			;;
		*)
			# should never happen
			echo -e "${badColor}network widget: programmer mistake${reset}" >&2
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
message+="public4|$publicIp4\n"
message+="public6|$publicIp6\n"

# output
echo 'network:'
echo -e "$message" | column -ts'|' | sed 's,^,  ,'
echo "  hostname $(uname -n)"
