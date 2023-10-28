#!/bin/bash
set -euo pipefail

# Output CPU usage in percent.
# Includes a noticeable sleep time.

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

# return idle and total CPU time since system start
cpuStats() {
	read -r -a cpu <<<"$(grep '^cpu ' /proc/stat)"
	iowait=${cpu[5]}
	idle=$((cpu[4] + cpu[5])) # idle + iowait
	unset 'cpu[0]'
	total=$((${cpu[@]/%/+}0))
	echo "$idle $iowait $total"
}

read -r -a start <<<"$(cpuStats)"
echo "measuring CPU stats..." >&2
sleep 0.5 # making this longer gives a better average
echo -e "$LINE_UP$LINE_CLEAR$LINE_UP" >&2 # clear previous message
read -r -a end <<<"$(cpuStats)"

iowait=$((end[1] - start[1]))
idle=$((end[0] - start[0]))
total=$((end[2] - start[2]))

cpuUsage=$((100 * (total - idle) / total)) # in percent
ioDelay=$((100 * iowait / total)) # in percent

echo "$cpuUsage $ioDelay"
