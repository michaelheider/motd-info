#!/bin/bash
set -euo pipefail

# Print overview of updates via `apt` and whether a restart is required.
# NOTE: You may want to install needsrestart to be notified of required restarts
#       due to library upgrades.
#       needrestart checks after every library upgrade, whether something needs restarting.
#       If `sudo needrestart` displays `Failed to check for processor microcode upgrades.`,
#       then in `/etc/needrestart/needrestart.conf` set `$nrconf{ucodehints} = 0;` to
#       disable microcode checks.
#       The command `sudo needrestart` only works with `sudo`. Otherwise you get
#       `needrestart: command not found`.
# Run it to see what it looks like.

# config
APT_CACHE_MAX_AGE="3days"

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

# check for apt
if ! "${HELPERS}/cmd-exists.sh" apt; then
	echo "${COLOR_INFO}apt not installed${RESET}"
	exit 0
fi

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
	echo -e "$LINE_UP$LINE_CLEAR$LINE_UP" >&2 # clear previous message
	cacheFresh=1
fi
# assemble message
if [ "$cacheFresh" -eq 1 ]; then
	nrPackages=$(apt -qq list --upgradable 2>/dev/null | wc -l)
	nrPackagesSecurity=$(apt -qq list --upgradable 2>/dev/null | { grep -c "\-security" || test $? = 1; })
	if [ "$nrPackages" -eq 0 ]; then
		upgradesMessage="${COLOR_GOOD}no upgrades${RESET}"
	else
		upgradesMessage="${COLOR_INFO}${nrPackages} upgrades${RESET}, "
		upgradesMessage+=$(colorIf "${nrPackagesSecurity}" '<' '1' " security")
	fi
else
	upgradesMessage="${COLOR_BAD}run \`apt update\`${RESET}"
fi

# print
echo 'packages:'
echo -e "  $upgradesMessage"
if [ -f "/run/reboot-required" ]; then
	# reboot required
	echo -e "  ${COLOR_BAD}reboot required${RESET}"
fi
