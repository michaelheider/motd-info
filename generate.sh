#!/bin/bash
set -euo pipefail

# relevant paths
folderPath=$(realpath "$(dirname "$0")")
toolPath="$folderPath/tools"
configPath="$folderPath/config.txt"
widgetsPath="$folderPath/widgets/"

source "${toolPath}/colors.sh"

cols=$(grep 'col=' "$configPath" | sed 's/.*col=//')

# execute widgets in columns
f=()
for i in $(seq 1 "$cols"); do
	f[i]=""
	for w in $(awk '!/^#/ {print $'$i'}' "$configPath"); do
		if [ -e "$widgetsPath/$w" ]; then
			f[i]+=$("$widgetsPath/$w")
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
	[[ -z ${motd} ]] && motd="${c}" || motd=$(paste <(echo -e "${motd}") <(echo -e "${c}") -d'@')
done
motd=${motd::-3} # remove trailing newlines
echo -e "${motd}" | sed 's,@, @ ,' | column -ts '@'
