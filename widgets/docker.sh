#!/bin/bash
set -euo pipefail

# Print status of services.
# Run it to see what it looks like.

# config
COLUMNS=2
FILTER='' # excluded containers separated by |

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

if ! "${HELPERS}/cmd-exists.sh" docker; then
	echo -e "${COLOR_INFO}docker not installed${RESET}"
	exit 0
fi

mapfile -t containers < <(docker ps -a --format "{{.Names}} {{.Status}}" | awk '!/^('"${FILTER}"')/{print $1,$2}')

out=''
for i in "${!containers[@]}"; do
	IFS=" " read -r name status <<<"${containers[$i]}"
	status=$(colorMatch "${status}" 'Up')
	out+="${name}|${status,,}|"
	(($(((i + 1) % COLUMNS)) == 0)) && out+='\n'
done
if [[ -z "${out}" ]]; then
	out='none'
fi
out+='\n'

echo 'docker containers:'
echo -e "${out}" | column -ts '|' | sed -e 's/^/  /'
