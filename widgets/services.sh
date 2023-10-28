#!/bin/bash
set -euo pipefail

# Print status of services.
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
failedTxt=$(head -n -5 <<<"$failedTxt")
failed=''
while read -r line; do
	# note: `-` must be last in the selector `[]` to not be treated as range.
	# For some reason, excaping with `\` does not work.
	# regex='^[● ] ([[:alnum:]._-]+) +([[:alpha:]]+) +([[:alpha:]]+) .*$'
	# regex='^([?![:space:]]+) +([[:alpha:]]+) +([[:alpha:]]+) .*$'
	regex='^(● )?([^[:space:]]+) +([[:alpha:]]+) +([[:alpha:]]+) .*$'
	[[ "$line" =~ $regex ]]
	name=${BASH_REMATCH[2]}
	name="${name%.*}" # remove '.service' and similar
	state=${BASH_REMATCH[4]}
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
echo -e "${failed}" | sed -e 's/^/  /'
