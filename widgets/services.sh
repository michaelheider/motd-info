#!/bin/bash
set -euo pipefail
LANG=en_US.UTF-8

# Print status of services.
# Run it to see what it looks like.

# config
columns=2 # fills row-major
servicesRealNames=('rsyslog' 'logrotate.timer' 'cron' 'networking' 'sshd' 'apache2')
servicesDisplayNames=('syslog' 'logrotate' 'cron' 'network' 'sshd' 'apache')

toolPath=$(realpath "$(dirname "$0")/../tools")
source "${toolPath}/colors.sh"

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
