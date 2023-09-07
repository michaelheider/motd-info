#!/bin/bash
set -euo pipefail
LANG=en_US.UTF-8

# Print system info.
# Run it to see what it looks like.

# config: cutoff values
cpuWarn=30  # %
memWarn=50  # %
swapWarn=50 # %
tempWarn=60 # °C

toolPath=$(realpath "$(dirname "$0")/../tools")
source "${toolPath}/colors.sh"

processes="$(ps --ppid 2 -p 2 --deselect | wc -l)"
load="$(cut -d' ' -f3 </proc/loadavg)"
users="$(w -h | wc -l)"
uptime="$(($(cut -d'.' -f1 </proc/uptime) / 3600 / 24))"
mem="$(free -b | awk 'FNR == 2 {p=100*$3/$2} END{printf("%0.f",p)}')"
swap="$(free -b | awk 'FNR == 3 {p=100*$3/$2} END{printf("%0.f",p)}')"
cores="$(grep -c '^processor' /proc/cpuinfo)"
cpu="$("${toolPath}/cpu.sh")"
if [[ -f '/sys/class/thermal/thermal_zone0/temp' ]]; then
	temp="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"
else
	temp="?"
fi

cpu=$(colorIf "${cpu}" '<' "${cpuWarn}" '%')
mem=$(colorIf "${mem}" '<' "${memWarn}" '%')
swap=$(colorIf "${swap}" '<' "${swapWarn}" '%')
temp=$(colorIf "${temp}" '<' "${tempWarn}" '°C')
load=$(colorIf "${load}" '<' "$cores")

table=''
table+="CPU|${cpu}|sys load|${load}\n"
table+="memory|${mem}|processes|${processes}\n"
table+="swap|${swap}|uptime|${uptime}d\n"
table+="temp|${temp}|users now|${users}\n"

echo 'system info:'
echo -e "${table}" | column -ts'|' -R "2,4" | sed 's,^,  ,'
