#!/bin/bash
set -euo pipefail

# Output CPU usage in percent.
# Includes a noticeable sleep time.

# return idle and total CPU time since system start
cpuStats() {
	read -r -a cpu <<<"$(grep '^cpu ' /proc/stat)"
	idle=$((cpu[4] + cpu[5]))
	unset 'cpu[0]'
	total=$((${cpu[@]/%/+}0))
	echo "$idle $total"
}

read -r -a start <<<"$(cpuStats)"
sleep 0.5 # making this longer gives a better average
read -r -a end <<<"$(cpuStats)"

idle=$((end[0] - start[0]))
total=$((end[1] - start[1]))

cpuUsage=$((100 * (total - idle) / total)) # in percent

echo "${cpuUsage}"
