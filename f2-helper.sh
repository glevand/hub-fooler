#!/usr/bin/env bash

# 2nd fool the fool helper.
# Usage: git rebase --exec f-helper.sh $(git rev-list --max-parents=0 --children HEAD | cut -d ' ' -f2) 

on_exit() {
	if [[ ${debug} || ${verbose} ]]; then
		echo '-------------------' >&2
	fi
}

parse_date_iso_8601() {
	local str=${1}
	local -n parse_date_iso_8601__year=${2}
	local -n parse_date_iso_8601__month=${3}
	local -n parse_date_iso_8601__day=${4}
	local -n parse_date_iso_8601__time=${5}

	local regex_year="[[:digit:]]{4}"
	local regex_month="[[:digit:]]{2}"
	local regex_day="[[:digit:]]{2}"
	local regex_time="[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}"

	local regex_full="^(${regex_year})-(${regex_month})-(${regex_day}) (${regex_time}) "

	if [[ ! "${str}" =~ ${regex_full} ]]; then
		echo "ERROR: No match '${str}'" >&2
		return 1
	fi

	parse_date_iso_8601__year="${BASH_REMATCH[1]}"
	parse_date_iso_8601__month="${BASH_REMATCH[2]}"
	parse_date_iso_8601__day="${BASH_REMATCH[3]}"
	parse_date_iso_8601__time="${BASH_REMATCH[4]}"

	if [[ ${debug} ]]; then
		echo "${FUNCNAME[0]}: str:   '${str}'" >&2
		echo "${FUNCNAME[0]}: year:  '${parse_date_iso_8601__year}'" >&2
		echo "${FUNCNAME[0]}: month: '${parse_date_iso_8601__month}'" >&2
		echo "${FUNCNAME[0]}: day:   '${parse_date_iso_8601__day}'" >&2
		echo "${FUNCNAME[0]}: time:  '${parse_date_iso_8601__time}'" >&2
	fi
	return 0
}

make_commit() {
	local date=${1}

	if [[ ${verbose} ]]; then
		echo "${FUNCNAME[0]}: ${date}" >&2
	fi

	GIT_AUTHOR_DATE="${date}" GIT_COMMITTER_DATE="${date}" \
		git commit -s --amend --no-edit --date="${date}" >/dev/null
}

#===============================================================================
export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-main}):\[\e[0m\] '

script_name="${0##*/}"

#set -x
#debug=1
verbose=1

trap "on_exit" EXIT
set -e

auth_date_current="$(git log -1 --format='%ai')"
auth_date_last="$(git log -1 --format='%ai' HEAD~)"

parse_date_iso_8601 "${auth_date_last}" year month day time

if [[ "${month:0:1}" == "0" ]]; then
	month="${month:(-1)}"
fi

if [[ "${day:0:1}" == "0" ]]; then
	day="${day:(-1)}"
fi

dow="$(date --date="${auth_date_last}")"
dow="${dow:0:3}"

case "${dow}" in
	Thu)
		new_day=$(( day + 1 ))
		echo "'${dow}': ${day} -> ${new_day}" >&2
		day="${new_day}"
		;;
	Fri)
		new_day=$(( day + 3 ))
		echo "'${dow}': ${day} -> ${new_day}" >&2
		day="${new_day}"
		;;
	*)
		new_day=$(( day + 1 + (RANDOM & 1) ))
		echo "'${auth_day_last}': ${day} -> ${new_day}" >&2
		day="${new_day}"
		;;
esac

if (( day > 30 )); then
	month="$(( month + 1 ))"
	day="$(( day - 30 ))"
fi

new_time="$(( 9 + (RANDOM & 7) )):$(( RANDOM & 59 )):$(( RANDOM & 59 ))"

new_date="${year}-${month}-${day} ${new_time}"

dow="$(date --date="${new_date}")"
dow="${dow:0:3}"

echo "${auth_date_current} -> ${dow}: ${new_date}" >&2

make_commit "${new_date}"

exit 0
