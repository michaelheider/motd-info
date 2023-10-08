#!/bin/bash
set -euo pipefail

# Print status of services.
# Run it to see what it looks like.

# config
COLUMNS=2 # fills row-major
SERVICES_REAL_NAMES=('systemd-journald' 'logrotate.timer' 'cron' 'networking' 'sshd')
SERVICES_DISPLAY_NAMES=('journald' 'logrotate' 'cron' 'network' 'sshd')

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

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
