#!/bin/bash
set -euo pipefail
export LC_TIME=POSIX # to have consistent date formats

# Show info about last logins.
# NOTE: This differs from sshd's last login prompt. sshd shows the last login of
#       the logged in user. This shows the last login of the N most recently
#       logged in users. This is because motd is executed as root (and sometimes
#       even cached and thus stale), so motd is user agnostic.
# INFO: To disable sshd's last login prompt, set the `PrintLastLog` flag to `no` in `/etc/ssh/sshd_config`.
# Run it to see what it looks like.

# config
NR=3 # max users displayed

HELPERS=$(realpath "$(dirname "$0")/../helpers")
# shellcheck source-path=../helpers
source "${HELPERS}/colors.sh"

# find OS and version
source /etc/os-release
# VERSION_ID might contain quotes, strip them
osVersion=${VERSION_ID//\"/}
osVersion=${osVersion%%.*}  # in case it's like "24.04"

# get appropriate command based on OS version
if { [[ "$ID" == "debian" ]] && [[ "$osVersion" -le 12 ]]; } || \
   { [[ "$ID" == "ubuntu" ]] && [[ "$osVersion" -le 24 ]]; }; then
    logCmd="lastlog"
elif { [[ "$ID" == "debian" ]] && [[ "$osVersion" -ge 13 ]]; } || \
     { [[ "$ID" == "ubuntu" ]] && [[ "$osVersion" -ge 25 ]]; }; then
	if ! "${HELPERS}/cmd-exists.sh" lastlog2; then
		echo -e "${COLOR_INFO}lastlog2 not installed${RESET}"
		exit 0
	fi
    logCmd="lastlog2"
fi

info=$($logCmd | tail -n +2 | { grep --invert-match --fixed-strings '**Never logged in**' || test $? = 1; })

# handle case with no last logins at all
if [ -z "$info" ]; then
	echo -e "${COLOR_INFO}no last logins${RESET}"
	exit 0
fi

# reformat to "UNIX_TIME_STAMP NAME SOURCE"
infoFormatted=''
while read -r line; do
	name=$(awk '{printf $1}' <<<"$line")

	date=$(awk '{ for (i=NF-4; i<=NF;i++){ printf $i; if (i != NF){ printf " " }} print "" }' <<<"$line")
	date=$(date --date="$date" +"%s")

	# If there is an IP, source will be the IP.
	# If there is no IP, source will be the port.
	# This makes sense, since the port is only really relevant if we have no IP.
	source=$(awk '{print $(NF-6)}' <<<"$line")

	infoFormatted+="$date $name $source"
	infoFormatted+=$'\n'
done <<<"$info"
infoFormatted=${infoFormatted::-1} # remove final newline

# sort and limit
lastLogins=$(sort -nr <<< "$infoFormatted" | head -n $NR )

# assemble message table
message=''
while read -r line; do
	date=$(awk '{printf $1}' <<<"$line")
	date=$(date --date="@$date" +'%Y-%m-%d %H:%M')

	name=$(awk '{printf $2}' <<<"$line")

	source=$(awk '{print $3}' <<<"$line")

	message+="$name|$date|$source\n"
done <<<"$lastLogins"

timeZone=$(date +'%Z')

# print message
echo "last logins ($timeZone)":
echo -e "$message" | column -ts'|' | sed 's,^,  ,'
