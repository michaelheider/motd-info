#!/bin/bash
set -euo pipefail

# Print disk health information.
# Run it to see what it looks like.
# Only displays something, if you have disks with
# direct (=no advacned options necessary) SMART support.

# config
POWER_ON_TIME_WARN=2.0    # years, decimal
TEMP_WARN=60              # °C
LOAD_CYCLE_WARN=500       # x1k cycles
REALLOCATED_SECTOR_WARN=1 # sectors

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

if [ "$(id -u)" -ne 0 ]; then # check if we are not root
	echo -e "${COLOR_INFO}disk health needs root${RESET}"
	exit 0
fi

# find disks
paths=$(lsblk -pno KNAME,TYPE | { grep disk || test $? = 1; } | awk '{print $1}')
mapfile -t disks <<<"$paths"
if [ ${#disks[@]} -eq 0 ]; then
	# no disk supports SMART
	echo -e "${COLOR_INFO}no disk health info${RESET}"
	exit 0
fi

# check for smartmontools
# only check here, when we are past the findin disks stage
if ! "${HELPERS}/cmd-exists.sh" smartctl; then
	echo -e "${COLOR_INFO}smartmontools not installed${RESET}"
	exit 0
fi

# assemble message
# format: device name | power on time | temp | load cycles | reallocated sectors
out=" |Chck|Pwr|T|LCyc|RSc\n"
for disk in "${disks[@]}"; do
	# get smart values
	smart="$(smartctl --attributes --health "$disk" || true)"
	# get (very rough) idea of the device type and hence the output format
	if grep -q 'NVMe' <<<"$smart"; then nvme=1; else nvme=0; fi

	# status
	status="$(awk '/SMART overall-health self-assessment test result:/ {print $6}' <<<"$smart")"
	if [ -n "$status" ]; then
		status="$(colorMatchCustom "$status" 'PASSED' 'pass' "$status")"
	else
		status='.'
	fi
	# power on time
	if [ $nvme -eq 0 ]; then
		powerOnTimeH="$(awk -- '/Power_On_Hours/ {print $10}' <<<"$smart")"
	else
		powerOnTimeH="$(awk -- '/Power On Hours/ {print $NF}' <<<"$smart")"
	fi
	powerOnTimeH=${powerOnTimeH/"’"/} # remove thousands separator U+2019 if present
	if [ -n "$powerOnTimeH" ]; then
		powerOnTimeY="$(bc -l <<<"$powerOnTimeH/24/365")"
		powerOnTimeY=$(printf '%3.1f\n' "$powerOnTimeY") # ensure leading 0, one decimal digit
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
	if [ $nvme -eq 0 ]; then
		t1="$(awk -- '/Temperature_Celsius/ {print $10}' <<<"$smart")"
		t2="$(awk -- '/Airflow_Temperature_Cel/ {print $10}' <<<"$smart")"
		temp=$((t1 > t2 ? t1 : t2)) # in case both temps are valid, take higher
	else
		temp="$(awk -- '/^Temperature:/ {print $(NF-1)}' <<<"$smart")"
	fi
	if [ "$temp" -eq 0 ]; then
		temp='.'
	else
		temp="$(colorIf "$temp" '<' "$TEMP_WARN" '°C')"
	fi
	# load cycle count
	if [ $nvme -eq 0 ]; then
		cycle="$(awk -- '/Load_Cycle_Count/ {print $10}' <<<"$smart")"
		if [ -n "$cycle" ]; then
			cycle="$(colorIf $((cycle / 1000)) '<' "${LOAD_CYCLE_WARN}" 'k')"
		else
			cycle='.'
		fi
	else
		cycle='.'
	fi
	# reallocated sector count
	if [ $nvme -eq 0 ]; then
		sectors="$(awk -- '/Reallocated_Sector_Ct/ {print $10}' <<<"$smart")"
		if [ -n "${sectors}" ]; then
			sectors="$(colorIf "$sectors" '<' $REALLOCATED_SECTOR_WARN)"
		else
			sectors='.'
		fi
	else
		sectors='.'
	fi
	# output
	out+="${disk##*/}|${status}|${powerOnTime}|${temp}|${cycle}|${sectors}\n"
done

echo 'disks health:'
echo -e "${out}" | column -ts'|' | sed 's,^,  ,'

# powerOnTimeH="$(awk -v SEP="$SEP" -v COL="$COL" -- 'match($0, "Power"SEP"On"SEP"Hours") {if (COL == -1) {COL=NF}; print $COL}' <<<"$smart")"
