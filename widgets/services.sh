#!/bin/bash
set -euo pipefail

# Print status of services.
# Run it to see what it looks like.

# config
COLUMNS=2 # fills row-major
SERVICES_REAL_NAMES=('rsyslog' 'logrotate.timer' 'cron' 'networking' 'sshd' 'apache2')
SERVICES_DISPLAY_NAMES=('syslog' 'logrotate' 'cron' 'network' 'sshd' 'apache')

TOOL_PATH=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${TOOL_PATH}/colors.sh"

out=''
for i in "${!SERVICES_REAL_NAMES[@]}"; do
	serviceStatus=$(systemctl is-active "${SERVICES_REAL_NAMES[i]}") || true
	serviceStatus=$(colorMatch "${serviceStatus}" 'active')
	out+="${SERVICES_DISPLAY_NAMES[$i]}|${serviceStatus}|"
	((((i + 1) % COLUMNS) == 0)) && out+='\n'
done
out+='\n'

echo 'services:'
echo -e "${out}" | column -ts '|' | sed -e 's/^/  /'
