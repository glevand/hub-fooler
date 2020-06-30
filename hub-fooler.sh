#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace
	echo "${script_name} - Generate a superstar git repository." >&2
	echo "Usage: ${script_name} [flags]" >&2
	echo "Option flags:" >&2
	echo "  -h --help        - Show this help and exit." >&2
	echo "  -v --verbose     - Verbose execution." >&2
	echo "Level:" >&2
	echo "  -1 --rock-star   - One commit per day, M-F (default)." >&2
	echo "  -2 --hero        - One-three commits per day, M-F." >&2
	echo "  -3 --untouchable - Two-five commits per day, everyday." >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts="hv123"
	local long_opts="help,verbose,rock-star,hero,untouchable"

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		#echo "${FUNCNAME[0]}: @${1}@ @${2}@"
		case "${1}" in
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			set -x
			#verbose=1
			shift
			;;
		-1 | --rock-star)
			level="rock-star"
			shift
			;;
		-2 | --hero)
			level="hero"
			shift
			;;
		-3 | --untouchable)
			level="untouchable"
			shift
			;;
		--)
			shift
			if [[ ${*} ]]; then
				set +o xtrace
				echo "${script_name}: ERROR: Got extra args: '${*}'" >&2
				usage
				exit 1
			fi
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

	if [[ ${need_cleanup} && -d ${tmp_dir} ]]; then
		rm -rf "${tmp_dir}"
	fi

	local end_sec="${SECONDS}"
	local end_min="$((end_sec / 60)).$(((end_sec * 100) / 60))"

	set +x
	if [[ ! ${need_cleanup} ]]; then
		echo "${script_name}: INFO: resuls in '${out_dir}'." >&2
	fi
	echo "${script_name}: Done: ${result}, ${end_sec} seconds (${end_min} min)." >&2
}

make_commit() {
	local date=${1}
	local file=${2}

	echo "${FUNCNAME[0]}: ${current_date%% *} ${file}"

	echo "${date}" > "${file}"
	git add . > /dev/null
	GIT_AUTHOR_DATE="${date}" GIT_COMMITTER_DATE="${date}" \
		git commit -m "Add ${file}" > /dev/null
}

#===============================================================================
export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-"?"}):\[\e[0m\] '
script_name="${0##*/}"

trap "on_exit 'failed'" EXIT
set -e

process_opts "${@}"

level="${level:-1}"

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

SECONDS=0

if ! test -x "$(command -v git)"; then
	echo "${script_name}: ERROR: Please install 'git'." >&2
	exit 1
fi

for ((current = 365 + 7; current; current--)); do
	day="$(date  --date="${current} days ago" +%a)"
	#echo "@${day}@"
	if [[ "${day}" == 'Mon' ]]; then
		break
	fi
done

need_cleanup=1
tmp_dir="$(mktemp --tmpdir --directory "${script_name}.XXXX")"

out_dir="${tmp_dir}/repo"

mkdir -p "${out_dir}"

cd "${out_dir}"
git init

current_date="$(date  --date="${current} days ago")"
echo "${script_name}: start: ${current_date}" >&2

for ((; current; current--)); do
	current_file="${out_dir}/fooler.${current}"
	current_date="$(date  --date="${current} days ago")"

	#echo "${current_date%% *}" >&2

	case "${level}" in
	rock-star)
		end_cnt=1
		for ((cnt = 1; cnt <= ${end_cnt}; cnt++)); do
			make_commit "${current_date}" "${current_file}.${cnt}"
		done
		if [[ "${current_date%% *}" == "Fri" ]]; then
			if [[ ${current} -le 2 ]]; then
				break;
			fi
			((current -= 2))
		fi
		;;
	hero)
		end_cnt=$((1 + (RANDOM & 1) + (RANDOM & 1)))
		for ((cnt = 1; cnt <= ${end_cnt}; cnt++)); do
			make_commit "${current_date}" "${current_file}.${cnt}"
		done
		if [[ "${current_date%% *}" == "Fri" ]]; then
			if [[ ${current} -le 2 ]]; then
				break;
			fi
			((current -= 2))
		fi
		;;
	untouchable)
		end_cnt=$((2 + (RANDOM & 3)))
		for ((cnt = 1; cnt <= ${end_cnt}; cnt++)); do
			make_commit "${current_date}" "${current_file}.${cnt}"
		done
		;;
	*)
		echo "${script_name}: ERROR: Internal, level = '${level}'" >&2
		exit 1
		;;
	esac
done

unset need_cleanup

trap "on_exit 'Success'" EXIT
exit 0
