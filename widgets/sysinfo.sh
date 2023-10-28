#!/bin/bash
set -euo pipefail

# Print system info.
# Run it to see what it looks like.

# config: cutoff values
CPU_WARN=30  # %
IO_DELAY_WARN=30  # % (percent of time CPU is explicitly waiting for IO)
MEM_WARN=50  # %
SWAP_WARN=50 # %
TEMP_WARN=60 # °C

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

processes="$(ps --ppid 2 -p 2 --deselect | wc -l)"
load="$(cut -d' ' -f1 </proc/loadavg)"
users="$(w -h | wc -l)"
uptime="$(($(cut -d'.' -f1 </proc/uptime) / 3600 / 24))"
mem="$(free -b | grep 'Mem' | awk '{ p=100*$3/$2; printf("%0.f",p) }')"
# if there is no swap space, it ouputs '-'
swap="$(free -b | grep 'Swap' | awk '{ if($2!=0) { p=100*$3/$2; printf("%0.f",p) } else { print "-" } }')"
cores="$(grep -c '^processor' /proc/cpuinfo)"
read -r -a cpuStats <<<"$("${HELPERS}/cpuStats.sh")"
cpuUsage=${cpuStats[0]}
ioDelay=${cpuStats[1]}
if [[ -f '/sys/class/thermal/thermal_zone0/temp' ]]; then
	temp="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"
else
	temp="?"
fi

cpuUsage=$(colorIf "${cpuUsage}" '<' "${CPU_WARN}" '%')
ioDelay=$(colorIf "${ioDelay}" '<' "${IO_DELAY_WARN}" '%')
mem=$(colorIf "${mem}" '<' "${MEM_WARN}" '%')
if [[ $swap != '-' ]]; then
	swap=$(colorIf "${swap}" '<' "${SWAP_WARN}" '%')
fi
temp=$(colorIf "${temp}" '<' "${TEMP_WARN}" '°C')
load=$(colorIf "${load}" '<' "$cores")

table=''
table+="CPU use|${cpuUsage}|IO delay|${ioDelay}\n"
table+="memory|${mem}|swap|${swap}\n"
table+="processes|${processes}|sys load|${load}\n"
table+="uptime|${uptime}d|temp|${temp}\n"
table+="users now|${users}\n"

echo 'system resources:'
echo -e "${table}" | column -ts'|' -R "2,4" | sed 's,^,  ,'
