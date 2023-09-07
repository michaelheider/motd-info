#!/bin/bash
set -euo pipefail

# Print status of services.
# Run it to see what it looks like.

# config
columns=2 # fills row-major
filter='' # excluded containers separated by |

toolPath=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${toolPath}/colors.sh"

if ! "${toolPath}/package-check.sh" lxc; then
	echo -e "${infoColor}lxc not installed${reset}"
	exit 0
fi

mapfile -t containers < <(lxc-ls -f | awk '!/^('"${filter}"')/{print $1,$2}' | sed '/^\s*$/d' | tail -n+2)

out=''
for i in "${!containers[@]}"; do
	IFS=" " read -r name status <<<"${containers[$i]}"
	status=$(colorMatch "${status}" 'RUNNING')
	out+="${name}|${status,,}|"
	(($(((i + 1) % columns)) == 0)) && out+='\n'
done
if [[ -z "${out}" ]]; then
	out='none'
fi
out+='\n'

echo 'containers:'
echo -e "${out}" | column -ts '|' | sed -e 's/^/  /'
