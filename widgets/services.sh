#!/bin/bash
set -euo pipefail

# Print status of services.
# Run it to see what it looks like.

# config
columns=2 # fills row-major
servicesRealNames=('rsyslog' 'logrotate.timer' 'cron' 'networking' 'sshd' 'apache2')
servicesDisplayNames=('syslog' 'logrotate' 'cron' 'network' 'sshd' 'apache')

TOOL_PATH=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${TOOL_PATH}/colors.sh"

out=''
for i in "${!servicesRealNames[@]}"; do
	serviceStatus=$(systemctl is-active "${servicesRealNames[i]}") || true
	serviceStatus=$(colorMatch "${serviceStatus}" 'active')
	out+="${servicesDisplayNames[$i]}|${serviceStatus}|"
	((((i + 1) % columns) == 0)) && out+='\n'
done
out+='\n'

echo 'services:'
echo -e "${out}" | column -ts '|' | sed -e 's/^/  /'
