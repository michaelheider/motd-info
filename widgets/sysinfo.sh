#!/bin/bash
set -euo pipefail

# Print system info.
# Run it to see what it looks like.

# config: cutoff values
CPU_WARN=30  # %
MEM_WARN=50  # %
SWAP_WARN=50 # %
TEMP_WARN=60 # °C

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

processes="$(ps --ppid 2 -p 2 --deselect | wc -l)"
load="$(cut -d' ' -f3 </proc/loadavg)"
users="$(w -h | wc -l)"
uptime="$(($(cut -d'.' -f1 </proc/uptime) / 3600 / 24))"
mem="$(free -b | grep 'Mem' | awk '{ p=100*$3/$2; printf("%0.f",p) }')"
# if there is no swap space, it ouputs '-'
swap="$(free -b | grep 'Swap' | awk '{ if($2!=0) { p=100*$3/$2; printf("%0.f",p) } else { print "-" } }')"
cores="$(grep -c '^processor' /proc/cpuinfo)"
cpu="$("${HELPERS}/cpu.sh")"
if [[ -f '/sys/class/thermal/thermal_zone0/temp' ]]; then
	temp="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"
else
	temp="?"
fi

cpu=$(colorIf "${cpu}" '<' "${CPU_WARN}" '%')
mem=$(colorIf "${mem}" '<' "${MEM_WARN}" '%')
if [[ $swap != '-' ]]; then
	swap=$(colorIf "${swap}" '<' "${SWAP_WARN}" '%')
fi
temp=$(colorIf "${temp}" '<' "${TEMP_WARN}" '°C')
load=$(colorIf "${load}" '<' "$cores")

table=''
table+="CPU|${cpu}|sys load|${load}\n"
table+="memory|${mem}|processes|${processes}\n"
table+="swap|${swap}|uptime|${uptime}d\n"
table+="temp|${temp}|users now|${users}\n"

echo 'system resources:'
echo -e "${table}" | column -ts'|' -R "2,4" | sed 's,^,  ,'
