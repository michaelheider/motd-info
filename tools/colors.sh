#!/bin/bash
set -euo pipefail

# Define colors and conditional coloring functions.

# reset
reset="\e[0m"           # reset style

# regular colors
black="\e[0;30m"        # black
red="\e[0;31m"          # red
green="\e[0;32m"        # green
yellow="\e[0;33m"       # yellow
blue="\e[0;34m"         # blue
purple="\e[0;35m"       # purple
cyan="\e[0;36m"         # cyan
white="\e[0;37m"        # white

# bold colors
bblack="\e[1;30m"       # black
bred="\e[1;31m"         # red
bgreen="\e[1;32m"       # green
byellow="\e[1;33m"      # yellow
bblue="\e[1;34m"        # blue
bpurple="\e[1;35m"      # purple
bcyan="\e[1;36m"        # cyan
bwhite="\e[1;37m"       # white


# c_if '2' '<' '5' '%'
c_if(){
	if (( "${1%%.*}" "$2" "${3%%.*}" )); then
		echo "${bgreen}$1${*:4}${reset}"
	else
		echo "${bred}$1${*:4}${reset}"
	fi
}

# c_if '2' '<' '5' 'r1' 'r2'adamshand
c_if_r(){
	if (( ${1%%.*} "$2" "${3%%.*}" )); then
		echo "${bgreen}${4}${reset}"
	else
		echo "${bred}${5}${reset}"
	fi
}

# c_match 'abc' 'def' 'pkgs'
c_match(){
	if [[ ${1%%.*} = "${2%%.*}" ]]; then
		echo "${bgreen}$1${*:3}${reset}"
	else
		echo "${bred}$1${*:3}${reset}"
	fi
}

# c_match_r 'abc' 'def' 'r1' 'r2'
c_match_r(){
	if [[ ${1%%.*} = "${2%%.*}" ]]; then
		echo "${bgreen}${3}${reset}"
	else
		echo "${bred}${4}${reset}"
	fi
}
