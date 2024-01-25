#!/bin/bash
set -euo pipefail

# Print status of overall system, any failed processes and number of zombie processes, if any.
# Run it to see what it looks like.

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

# Get the value corresponding to the provided key.
# @param $1 key to find in `systemctl show`
findInfo() {
	key="$1"
	systemInfo=$(systemctl show)
	line=$(grep "$key" <<<"$systemInfo")
	regex="$key=(.*)"
	[[ "$line" =~ $regex ]]
	value=${BASH_REMATCH[1]}
	echo "$value"
}

# overall system state
systemState=$(findInfo 'SystemState')
systemState=$(colorMatch "$systemState" 'running')

# nr of zombie processes
zombies=$(ps axo pid=,stat= | awk '$2~/^Z/ { print }' | wc -l)

# count failed
failedUnitsN=$(findInfo 'NFailedUnits')

# find failed or otherwise not active
failedTxt=$(systemctl list-units)
failedTxt=$(tail -n +2 <<<"$failedTxt")
failedTxt=$(head -n -6 <<<"$failedTxt")
failed=''
while IFS='' read -r line; do
	# sample line (incl. header that is cut off):
	#   UNIT                        LOAD   ACTIVE     SUB          DESCRIPTION
	#   systemd-journald.service    loaded active     running      Journal Service
	regex='^((● )|  )([[:alnum:][:punct:]]+) +([[:alpha:]]+) +([[:alpha:]]+) +([[:alpha:]]+) .*$'
	[[ "$line" =~ $regex ]]
	name=${BASH_REMATCH[3]}
	name="${name%.*}" # remove '.service' and similar
	state=${BASH_REMATCH[5]}
	if [ "$state" == 'failed' ]; then
		failed+="$name: $COLOR_BAD$state$RESET\n"
	elif [ "$state" != 'active' ]; then
		failed+="$name: $COLOR_INFO$state$RESET\n"
	fi
done <<<"$failedTxt"

out=''
out+="system $systemState"
if ((failedUnitsN > 0)); then
	out+=", $failedUnitsN errors"
fi
if ((zombies > 0)); then
	out+=", $COLOR_INFO$zombies zombies$RESET"
fi

echo -e "$out"
echo -en "${failed}" | sed -e 's/^/  /'
