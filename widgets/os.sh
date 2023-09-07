#!/bin/bash
set -euo pipefail

# Print OS information.
# Run it to see what it looks like.

TOOL_PATH=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${TOOL_PATH}/colors.sh"

if ! "${TOOL_PATH}/package-check.sh" lsb-release; then
	echo "lsb-release not installed"
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
