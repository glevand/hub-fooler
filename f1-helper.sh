#!/usr/bin/env bash

# 1st fool the fool helper.
# Usage: git rebase --exec f1-helper.sh --root

on_exit() {
	if [[ ${debug} || ${verbose} ]]; then
		echo '-------------------' >&2
	fi
}

parse_date_2() {
	local str=${1}
	local -n _parse_date_2__day=${2}
	local -n _parse_date_2__month=${3}
	local -n _parse_date_2__date=${4}
	local -n _parse_date_2__year=${5}
	local -n _parse_date_2__time=${6}

	local regex_day="[[:alpha:]]{3}"
	local regex_month="[[:alpha:]]{3}"
	local regex_date="[[:digit:]][[:digit:]]?"
	local regex_time="([[:digit:]]{2}:){2}[[:digit:]]{2}"
	local regex_year="[[:digit:]]{4}"

	local regex_full="^(${regex_day}) (${regex_month}) (${regex_date}) (${regex_time}) (${regex_year})"

	if [[ ! "${str}" =~ ${regex_full} ]]; then
		echo "ERROR: No match '${str}'" >&2
		return 1
	fi

	_parse_date_2__day="${BASH_REMATCH[1]}"
	_parse_date_2__month="${BASH_REMATCH[2]}"
	_parse_date_2__date="${BASH_REMATCH[3]}"
	_parse_date_2__time="${BASH_REMATCH[4]}"
	_parse_date_2__year="${BASH_REMATCH[6]}"

	if [[ ${debug} ]]; then
		echo "${FUNCNAME[0]}: str:   '${str}'" >&2
		echo "${FUNCNAME[0]}: day:   '${_parse_date_2__day}'" >&2
		echo "${FUNCNAME[0]}: month: '${_parse_date_2__month}'" >&2
		echo "${FUNCNAME[0]}: date:  '${_parse_date_2__date}'" >&2
		echo "${FUNCNAME[0]}: year:  '${_parse_date_2__year}'" >&2
		echo "${FUNCNAME[0]}: time:  '${_parse_date_2__time}'" >&2
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

#debug=1
#verbose=1

trap "on_exit" EXIT
set -e

commit="$(git log -1 --format='%h')"
auth_date="$(git log -1 --format='%ad')"

parse_date_2 "${auth_date}" day month date year time

hour=${time:0:2}

if (( year == 2020 )); then
	if [[ 'Jan Feb Mar Apr May' != *"${month}"* ]]; then
		if [[ 'Sat Sun' != *"${day}"* ]]; then
			if (( hour < 18 )); then
				need_fix=1
				if [[ ${verbose} ]]; then
					echo "NG-1: ${auth_date}" >&2
				fi
			fi
		fi
	fi
fi

if (( year >= 2021 )); then
	if [[ 'Sat Sun' != *"${day}"* ]]; then
		if (( hour < 18 )); then
			need_fix=1
			if [[ ${verbose} ]]; then
				echo "NG-2: ${auth_date}" >&2
			fi
		fi
	fi
fi

if [[ ! ${need_fix} ]]; then
	if [[ ${verbose} ]]; then
		echo "OK: ${auth_date}" >&2
	fi
	exit 0
fi

new_hour=$((18 + (RANDOM & 4)))

new_date="${day} ${month} ${date} ${new_hour}${time:(-6)} ${year} -0800"

if [[ ${verbose} ]]; then
	echo "H: ${hour} -> ${new_hour}" >&2
	echo "${auth_date}" >&2
	echo "${new_date}" >&2
else
	echo "Update: ${auth_date} -> ${new_date}" >&2
fi

make_commit "${new_date}"

exit 0
