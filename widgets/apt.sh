#!/bin/bash
set -euo pipefail
LANG=en_US.UTF-8

# Print overview of updates via `apt` and whether a restart is required.
# Run it to see what it looks like.

# config
APT_CACHE_MAX_AGE="3days"

toolPath=$(realpath "$(dirname "$0")/../tools")
source "${toolPath}/colors.sh"

# get latest execution time of `apt update`
# how Ansible does it
# https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/apt.py#L1151C14-L1151C14 (2023-09-06)
APT_UPDATE_SUCCESS_STAMP_PATH="/var/lib/apt/periodic/update-success-stamp"
APT_LISTS_PATH="/var/lib/apt/lists"
cacheFresh=0
if [ -n "$(find -H "$APT_UPDATE_SUCCESS_STAMP_PATH" -newermt "now -$APT_CACHE_MAX_AGE" 2>/dev/null)" ]; then
	cacheFresh=1
elif [ -n "$(find -H "$APT_LISTS_PATH" -maxdepth 0 -newermt "now -$APT_CACHE_MAX_AGE" 2>/dev/null)" ]; then
	cacheFresh=1
fi
# update if cash not fresh and we are root
if [ "$cacheFresh" -eq 0 ] && [ "$(id -u)" -eq 0 ]; then
	echo "running apt update..." >&2
	apt-get -qq update
	echo -e "$oneLineUp$clearLine$oneLineUp" >&2 # clear previous message
	cacheFresh=1
fi
# assemble message
if [ "$cacheFresh" -eq 1 ]; then
	nrPackages=$(apt -qq list --upgradable 2>/dev/null | wc -l)
	nrPackagesSecurity=$(apt -qq list --upgradable 2>/dev/null | { grep -c "\-security" || test $? = 1; })
	if [ "$nrPackages" -eq 0 ]; then
		upgradesMessage="${goodColor}no upgrades${reset}"
	else
		upgradesMessage="${infoColor}${nrPackages} upgrades${reset}, "
		upgradesMessage+=$(colorIf "${nrPackagesSecurity}" '<' '1' " security")
	fi
else
	upgradesMessage="${badColor}run \`apt update\`${reset}"
fi

# print
echo 'packages:'
echo -e "  $upgradesMessage"
if [ -f "/run/reboot-required" ]; then
	# reboot required
	echo -e "  ${badColor}reboot required${reset}"
fi
