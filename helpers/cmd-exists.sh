#!/bin/bash
set -euo pipefail

# Check whether a command exists.
# The command is given as the first argument.
# Usage example:
# if ! "${TOOL_PATH}/cmd-exists.sh" docker; then
#     echo "${COLOR_INFO}docker not available${RESET}"
#     exit 0
# fi

CMD=$1
if ! command -v "$CMD" &>/dev/null; then
	exit 1
fi
