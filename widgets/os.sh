#!/bin/bash
set -euo pipefail

# Print OS information.
# Run it to see what it looks like.

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

if ! "${HELPERS}/cmd-exists.sh" lsb_release; then
	echo "${COLOR_INFO}lsb-release not installed${RESET}"
	exit 0
fi

distro=$(lsb_release -rics 2>/dev/null | tr '\n' ' ')
distro=${distro::-1} # remove trailing space

table=''
table+="distro:|$distro\n"
table+="kernel:|$(uname -sr)\n"
table+="arch:|$(uname -m)\n"

echo 'OS:'
echo -e "${table}" | column -ts'|' | sed 's,^,  ,'
