#!/bin/bash
set -euo pipefail

# Define colors and conditional coloring functions.

# reset
RESET='\e[0m'

# regular colors
BLACK='\e[0;30m'
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
PURPLE='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'

# bold colors
BLACK_B='\e[1;30m'
RED_B='\e[1;31m'
GREEN_B='\e[1;32m'
YELLOW_B='\e[1;33m'
BLUE_B='\e[1;34m'
PURPLE_B='\e[1;35m'
CYAN_B='\e[1;36m'
WHITE_B='\e[1;37m'

# semantic colors
COLOR_GOOD=$GREEN
COLOR_BAD=$RED_B
COLOR_INFO=$YELLOW

# other
LINE_CLEAR='\e[K'
LINE_UP='\e[1A'
LINE_UP2='\e[2A' # can also do higher numbers

# conditional coloring functions

# example use: colorIf '2' '<' '5' '%'
colorIf() {
	if (( "${1%%.*}" "$2" "${3%%.*}" )); then
		echo "${COLOR_GOOD}$1${*:4}${RESET}"
	else
		echo "${COLOR_BAD}$1${*:4}${RESET}"
	fi
}

# example use: colorIfCustom '2' '<' '5' 'r1' 'r2'
colorIfCustom() {
	if (( "${1%%.*}" "$2" "${3%%.*}" )); then
		echo "${COLOR_GOOD}$4${RESET}"
	else
		echo "${COLOR_BAD}$5${RESET}"
	fi
}

# example use: colorMatch 'abc' 'def' 'pkgs'
colorMatch() {
	if [[ "${1%%.*}" = "${2%%.*}" ]]; then
		echo "${COLOR_GOOD}$1${*:3}${RESET}"
	else
		echo "${COLOR_BAD}$1${*:3}${RESET}"
	fi
}

# example use: colorMatchCustom 'abc' 'def' 'r1' 'r2'
colorMatchCustom() {
	if [[ "${1%%.*}" = "${2%%.*}" ]]; then
		echo "${COLOR_GOOD}$3${RESET}"
	else
		echo "${COLOR_BAD}$4${RESET}"
	fi
}
