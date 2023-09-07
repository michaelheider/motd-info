#!/bin/bash
set -euo pipefail

# Print disk health information.
# Run it to see what it looks like.
# Only displays something, if you have disks with
# direct (=no advacned options necessary) SMART support.

# config
powerOnWarn="2.0" # years, decimal
tempWarn=50       # °C
loadCycleWarn=500  # x1k cycles

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
	ageH="$(echo "${smart}" | awk '/Power_On_Hours/ {print $10}')"
	if [[ -n "${ageH}" ]]; then
		ageY="$(bc -l <<<"scale=1; $((ageH / 24))/365")"
		ageY=$(printf '%3.1f\n' "$ageY") # ensure leading 0
		if [ "$(bc -l <<<"$ageY < $powerOnWarn")" -eq 1 ]; then
			color=$COLOR_GOOD
		else
			color=$COLOR_BAD
		fi
		age="${color}${ageY}y${RESET}"
	else
		age='.'
	fi
	# temp
	t1="$(echo "${smart}" | awk '/Temperature_Celsius/ {print $10}')"
	t2="$(echo "${smart}" | awk '/Airflow_Temperature_Cel/ {print $10}')"
	temp=$((t1 > t2 ? t1 : t2))
	temp="$(colorIf "${temp}" '<' "${tempWarn}" '°')"
	# load cycle count
	cycle="$(echo "${smart}" | awk '/Load_Cycle_Count/ {print $10}')"
	[[ -n "${cycle}" ]] && cycle="$(colorIf $((cycle / 1000)) '<' "${loadCycleWarn}" 'k')" || cycle='.'
	# reallocated sector count
	sect="$(echo "${smart}" | awk '/Reallocated_Sector_Ct/ {print $10}')"
	# status
	status="$(echo "${smart}" | awk '/SMART overall-health self-assessment test result:/ {print $6}')"
	status="$(colorMatch "${status}" 'PASSED')"
	# output
	out+="${disk##*/}|${status}|${age}|${temp}|${cycle}|${sect}\n"
done

echo 'disks health:'
echo -e "${out}" | column -ts'|' | sed 's,^,  ,'
