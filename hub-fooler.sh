#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace

	{
		echo "${script_name} - Generate a superstar git repository."
		echo "Usage: ${script_name} [flags]"
		echo "Option flags:"
		echo "  -s --start       - Start date. Default: '${start_date}'."
		echo "  -e --end         - End date. Default: '${end_date}'."
		echo "  -h --help        - Show this help and exit."
		echo "  -v --verbose     - Verbose execution."
		echo "  -g --debug       - Extra verbose execution."
		echo "Level:"
		echo "  -1 --light-weight - One commit every few days."
		echo "  -2 --rock-star    - One commit per day, M-F (default)."
		echo "  -3 --hero         - One to three commits per day, M-F."
		echo "  -4 --untouchable  - Two to five commits per day, everyday."
		echo "Info:"
		print_project_info
	} >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts='s:e:hvg1234'
	local long_opts='start:,end:,help,verbose,debug,light-weight,rock-star,hero,untouchable'

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		# echo "${FUNCNAME[0]}: (${#}) '${*}'"
		case "${1}" in
		-s | --start)
			start_date="${2}"
			shift 2
			;;
		-e | --end)
			end_date="${2}"
			shift 2
			;;
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			verbose=1
			shift
			;;
		-g | --debug)
			verbose=1
			debug=1
			set -x
			shift
			;;
		-1 | --light-weight)
			level="light-weight"
			shift
			;;
		-2 | --rock-star)
			level="rock-star"
			shift
			;;
		-3 | --hero)
			level="hero"
			shift
			;;
		-4 | --untouchable)
			level="untouchable"
			shift
			;;
		--)
			shift
			extra_args="${*}"
			break
			;;
		*)
			echo "${script_name}: ERROR: Internal opts: '${*}'" >&2
			exit 1
			;;
		esac
	done
}

on_exit() {
	local result=${1}
	local sec=${SECONDS}

	if [[ ${need_cleanup} && -d "${tmp_dir}" ]]; then
		rm -rf "${tmp_dir}"
	fi

	set +x
	if [[ ! ${need_cleanup} ]]; then
		echo "${script_name}: INFO: Results in '${out_dir}'." >&2
		echo "${script_name}: INFO: ${counter} commits." >&2
	fi
	echo "${script_name}: Done: ${result}, ${sec} sec ($(sec_to_min "${sec}") min)." >&2
}

on_err() {
	local f_name=${1}
	local line_no=${2}
	local err_no=${3}

	echo "${script_name}: ERROR: function=${f_name}, line=${line_no}, result=${err_no}" >&2
	exit "${err_no}"
}

print_project_banner() {
	echo "${script_name} (@PACKAGE_NAME@) - ${start_time}"
}

print_project_info() {
	echo "  @PACKAGE_NAME@ ${script_name}"
	echo "  Version: @PACKAGE_VERSION@"
	echo "  Project Home: @PACKAGE_URL@"
}

sec_to_min() {
	local sec=${1}
	local min="$(( sec / 60 ))"
	local frac_10="$(( (sec - min * 60) * 10 / 60 ))"
	local frac_100="$(( (sec - min * 60) * 100 / 60 ))"

	if (( frac_10 != 0 )); then
		frac_10=''
	fi

	echo "${min}.${frac_10}${frac_100}"
}

check_program() {
	local prog="${1}"
	local path="${2}"

	if ! test -x "$(command -v "${path}")"; then
		echo "${script_name}: ERROR: Please install '${prog}'." >&2
		exit 1
	fi
}

make_commit() {
	local date=${1}
	local file=${2}
	local name="${file##*/}"

# 	if [[ ${verbose} ]]; then
# 		echo "${FUNCNAME[0]}: ${date%% *} ${name}"
# 	fi

	echo "${date}" >> "${file}"
	git add . > /dev/null
	GIT_AUTHOR_DATE="${date}" GIT_COMMITTER_DATE="${date}" \
		git commit -m "Add '${date}'" > /dev/null
}

make_readme() {
	local date="${1}"
	local dir="${2}"

	if [[ ${verbose} ]]; then
		echo "${FUNCNAME[0]}: ${date}"
	fi

	mkdir -p "${dir}"
	echo 'Output of hub-fooler' > "${dir}/README.md"
	echo >> "${dir}/README.md"
	print_project_info >> "${dir}/README.md"

	git add . > /dev/null
	GIT_AUTHOR_DATE="${date}" GIT_COMMITTER_DATE="${date}" \
		git commit -m 'Add README' > /dev/null
}

#===============================================================================
export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-main}):\[\e[0m\] '

script_name="${0##*/}"

SECONDS=0
start_time="$(date +%Y.%m.%d-%H.%M.%S)"

trap 'on_exit "Failed"' EXIT
trap 'on_err ${FUNCNAME[0]:-main} ${LINENO} ${?}' ERR
trap 'on_err SIGUSR1 ? 3' SIGUSR1

set -eE
set -o pipefail
set -o nounset

start_date=''
end_date=''
usage=''
verbose=''
debug=''
level='rock-star'
need_cleanup=1
tmp_dir=''

print_project_banner >&2

process_opts "${@}"

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

if [[ ${extra_args} ]]; then
	set +o xtrace
	echo "${script_name}: ERROR: Got extra args: '${extra_args}'" >&2
	usage
	exit 1
fi

git="${git:-git}"
check_program 'git' "${git}"

today_day="$(( $(date +%s) / 86400 ))"

date="${date:-date}"
check_program 'date' "${date}"

if [[ ! ${start_date} && ${end_date} ]]; then
	set +o xtrace
	echo "${script_name}: ERROR: Got --end without --start" >&2
	usage
	exit 1
fi

if [[ ${verbose} && ${start_date} && ${end_date} ]]; then
	echo "Got start_date = ${start_date}"
	echo "Got end_date   = ${end_date}"
fi

if [[ ${start_date} && ! ${end_date} ]]; then
	if [[ ${verbose} ]]; then
		echo "Got start_date = ${start_date}"
	fi

	start_sec="$( date +%s --date="${start_date}" )"
	end_sec="$(( ${start_sec} + (365 * 86400) ))"
	end_date="$(date --date="@${end_sec}" -Idate)"
fi

if [[ ! ${start_date} && ! ${end_date} ]]; then
	if [[ ${verbose} ]]; then
		echo 'Got none'
	fi

	today_sec="$(( $(date +%s) ))"
	end_date="$(date --date="@${today_sec}" -Idate)"
	start_sec="$(( ${today_sec} - (365 * 86400) ))"
	start_date="$(date --date="@${start_sec}" -Idate)"
fi

start_day="$(( ${today_day} - ($(date +%s -d "${start_date}") / 86400) ))"
end_day="$((  ${today_day} - ($(date +%s -d "${end_date}") / 86400) ))"

days_diff="$(( ${start_day} - ${end_day} ))"

if [[ ${verbose} ]]; then
	echo "start_date = ${start_date}"
	echo "end_date   = ${end_date}"
	echo "today_day = ${today_day}"
	echo "start_day = ${start_day}"
	echo "end_day   = ${end_day}"
	echo "days_diff  = ${days_diff}"
fi

if (( ${days_diff} <= 0 )); then
	set +o xtrace
	echo "${script_name}: ERROR: --end is before --start" >&2
	exit 1
fi

for (( current_day = ${start_day} - 7; current_day; current_day++ )); do
	day="$(date  --date="${current_day} days ago" +%a)"
	if [[ ${verbose} ]]; then
		echo "@${current_day} = ${day}@"
	fi
	if [[ "${day}" == 'Mon' ]]; then
		break
	fi
done

tmp_dir="$(mktemp --tmpdir --directory "${script_name}.XXXX")"

out_dir="${tmp_dir}/repo"
out_file="${out_dir}/fooler-out"

mkdir -p "${out_dir}"

cd "${out_dir}"
git init -q -b master

current_date="$(date --date="${current_day} days ago")"
echo "${script_name}: start: ${current_date}" >&2

make_readme "${current_date}" "${out_dir}"

counter='0'

for (( ; current_day >= end_day; current_day-- )); do
	current_date="$(date  --date="${current_day} days ago")"

	if [[ ${verbose} ]]; then
		echo "current_day = ${current_day} (${current_date%% *})" >&2
	fi

	case "${level}" in
	light-weight)
		make_commit "${current_date}" "${out_file}"
		counter="$((counter + 1))"
		days_off=$((1 + (RANDOM & 3)))
		(( current_day -= days_off )) || :
		;;
	rock-star)
		make_commit "${current_date}" "${out_file}"
		counter="$((counter + 1))"
		if [[ "${current_date%% *}" == "Fri" ]]; then
			(( current_day -= 2 )) || :
		fi
		;;
	hero)
		end_cnt=$((1 + (RANDOM & 1) + (RANDOM & 1)))
		for ((cnt = 1; cnt <= ${end_cnt}; cnt++)); do
			make_commit "${current_date}" "${out_file}.${cnt}"
			counter="$((counter + 1))"
		done
		if [[ "${current_date%% *}" == "Fri" ]]; then
			(( current_day -= 2 )) || :
		fi
		;;
	untouchable)
		end_cnt=$((2 + (RANDOM & 3)))
		for (( cnt = 1; cnt <= ${end_cnt}; cnt++ )); do
			make_commit "${current_date}" "${out_file}.${cnt}"
			counter="$((counter + 1))"
		done
		;;
	*)
		echo "${script_name}: ERROR: Internal, level = '${level}'" >&2
		exit 1
		;;
	esac
done

current_date="$(date --date="${current_day} days ago")"
echo "${script_name}: end:   ${current_date}" >&2

need_cleanup=''

trap 'on_exit "Success"' EXIT
exit 0
