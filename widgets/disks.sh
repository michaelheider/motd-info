#!/bin/bash
set -euo pipefail

# Print disk health information.
# Run it to see what it looks like.
# Only displays something, if you have disks with
# direct (=no advacned options necessary) SMART support.

# config
POWER_ON_TIME_WARN="2.0"  # years, decimal
TEMP_WARN=50              # °C
LOAD_CYCLE_WARN=500       # x1k cycles
REALLOCATED_SECTOR_WARN=1 # sectors

TOOL_PATH=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${TOOL_PATH}/colors.sh"

if [ "$(id -u)" -ne 0 ]; then # check if we are not root
	echo -e "${COLOR_INFO}disk health needs root${RESET}"
	exit 0
fi

mapfile -t disks < <(lsblk -Spno KNAME)
if [ ${#disks[@]} -eq 0 ]; then
	# no disk supports SMART
	echo -e "${COLOR_INFO}no disk health info${RESET}"
	exit 0
fi
out=" |Status|Pwr|Temp|Cycl|Real\n"
for disk in "${disks[@]}"; do
	smart="$(smartctl -A -H -d sat "${disk}" || true)"
	# power on time
	powerOnTimeH="$(echo "${smart}" | awk '/Power_On_Hours/ {print $10}')"
	if [[ -n "${powerOnTimeH}" ]]; then
		powerOnTimeY="$(bc -l <<<"scale=1; $((powerOnTimeH / 24))/365")"
		powerOnTimeY=$(printf '%3.1f\n' "$powerOnTimeY") # ensure leading 0
		if [ "$(bc -l <<<"$powerOnTimeY < $POWER_ON_TIME_WARN")" -eq 1 ]; then
			color=$COLOR_GOOD
		else
			color=$COLOR_BAD
		fi
		powerOnTime="${color}${powerOnTimeY}y${RESET}"
	else
		powerOnTime='.'
	fi
	# temp
	t1="$(echo "${smart}" | awk '/Temperature_Celsius/ {print $10}')"
	t2="$(echo "${smart}" | awk '/Airflow_Temperature_Cel/ {print $10}')"
	temp=$((t1 > t2 ? t1 : t2))
	temp="$(colorIf "${temp}" '<' "${TEMP_WARN}" '°')"
	# load cycle count
	cycle="$(echo "${smart}" | awk '/Load_Cycle_Count/ {print $10}')"
	[[ -n "${cycle}" ]] && cycle="$(colorIf $((cycle / 1000)) '<' "${LOAD_CYCLE_WARN}" 'k')" || cycle='.'
	# reallocated sector count
	sect="$(echo "${smart}" | awk '/Reallocated_Sector_Ct/ {print $10}')"
	[[ -n "${sect}" ]] && sect="$(colorIf "$sect" '<' $REALLOCATED_SECTOR_WARN)" || sect='.'
	# status
	status="$(echo "${smart}" | awk '/SMART overall-health self-assessment test result:/ {print $6}')"
	status="$(colorMatch "${status}" 'PASSED')"
	# output
	out+="${disk##*/}|${status}|${powerOnTime}|${temp}|${cycle}|${sect}\n"
done

echo 'disks health:'
echo -e "${out}" | column -ts'|' | sed 's,^,  ,'
