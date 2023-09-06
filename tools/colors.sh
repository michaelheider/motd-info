#!/bin/bash
set -euo pipefail

# Define colors and conditional coloring functions.

# reset
reset="\e[0m"

# regular colors
black="\e[0;30m"      
red="\e[0;31m"         
green="\e[0;32m"      
yellow="\e[0;33m"    
blue="\e[0;34m"        
purple="\e[0;35m"     
cyan="\e[0;36m"        
white="\e[0;37m"       

# bold colors
bblack="\e[1;30m"     
bred="\e[1;31m"      
bgreen="\e[1;32m"     
byellow="\e[1;33m"     
bblue="\e[1;34m"     
bpurple="\e[1;35m"   
bcyan="\e[1;36m"      
bwhite="\e[1;37m"    

# other
clearLine="\e[K"
oneLineUp="\e[1A" # can replace 1 with a higher integer
twoLinesUp="\e[2A"


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
	if (( "${1%%.*}" "$2" "${3%%.*}" )); then
		echo "${bgreen}${4}${reset}"
	else
		echo "${bred}${5}${reset}"
	fi
}

# c_match 'abc' 'def' 'pkgs'
c_match(){
	if [[ "${1%%.*}" = "${2%%.*}" ]]; then
		echo "${bgreen}$1${*:3}${reset}"
	else
		echo "${bred}$1${*:3}${reset}"
	fi
}

# c_match_r 'abc' 'def' 'r1' 'r2'
c_match_r(){
	if [[ "${1%%.*}" = "${2%%.*}" ]]; then
		echo "${bgreen}${3}${reset}"
	else
		echo "${bred}${4}${reset}"
	fi
}
