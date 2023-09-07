#!/bin/bash
set -euo pipefail
export LANG=en_US.UTF-8 # fix $LANG

# Get the scripts location.
# $SOURCE is the script, $DIR is the containing directory.
# Both are absolute and without any symlinks in all conditions.
# https://stackoverflow.com/a/246128/11391248 (2023-09-07)
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
	SOURCE=$(readlink "$SOURCE")
	# if $SOURCE was a relative symlink,
	# we need to resolve it relative to the path where the symlink file was located
	[[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

toolPath="$DIR/tools"
configPath="$DIR/config.txt"
widgetsPath="$DIR/widgets"

# shellcheck source-path=./tools
source "${toolPath}/colors.sh"

cols=$(grep 'col=' "$configPath" | sed 's/.*col=//')

# execute widgets
f=()
for i in $(seq 1 "$cols"); do
	f[i]=""
	for w in $(awk '!/^#/ {print $'$i'}' "$configPath"); do
		if [ -e "$widgetsPath/$w.sh" ]; then
			f[i]+=$("$widgetsPath/$w.sh")
			f[i]+="\n\n"
		else
			if [[ $w != '-' ]]; then
				echo -e "${badColor}no widget '$w'${reset}" >&2
			fi
		fi
	done
done

# print
motd=''
for c in "${f[@]}"; do
	[[ -z ${motd} ]] && motd="${c}" || motd=$(paste -d'@' <(echo -e "${motd}") <(echo -e "${c}"))
done
motd=${motd::-3} # remove trailing newlines
echo -e "${motd}" | sed 's,@, @ ,' | column -ts'@'
echo ''
