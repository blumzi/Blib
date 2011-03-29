#!/bin/bash

module_include flock const list str error

#
# We implement a hierarchical mutex namespace, i.e. names can be x/y/z.
#

function _mutex_name_to_path() {
	declare mutex_name="${1}"

	echo ${_mutex_dir}/${mutex_name}.mutex
}

function mutex_is_locked() {
	declare mutex_name="${1}"
	declare mutex_path=$( _mutex_name_to_path "${mutex_name}" )

	if [ ! -e ${mutex_path} ]; then
		return 1
	fi
	flock_wrlock --non-block --file ${mutex_path} bash -c "exit 0"
	[ $? -eq ${const_status_flock_would_block} ] && return 0 || return 1
}

function mutex_trylock() {
	declare mutex_name mutex_path mutexes
	declare command escaped_command rc pid i timeout=10 owner
	declare async=false forever
	declare opts=$( getopt -o 't:' --long async,mutex:,command:,escaped-command:,forever -n "${prog}" -- "$@" )

	eval set -- "${opts}"

	while true; do
		case "${1}" in
		--mutex)
			mutex_name="${2}"
			shift 2
			mutex_path=$( _mutex_name_to_path "${mutex_name}" )
			;;

		--forever)
			forever="--forever"
			shift 1
			;;
		--async)
			async=true
			shift 1
			;;
		
		--escaped-command)
			escaped_command="${2}"
			command="$( str_unescape "${escaped_command}" )"
			shift 2
			;;

		--command)
			command="${2}"
			escaped_command="$( str_escape "${command}" )"
			shift 2
			;;
		--)
			shift
			break
			;;
		esac
	done

	if ! ${async} && [ ! "${command}" ]; then
		log_msg "${FUNCNAME}: called without --command or --async"
		return 1
	fi

	mutex_tryprune ${mutex_name}

	if [ ! -e ${mutex_path} ]; then
		mkdir -p $( dirname ${mutex_path} )
		touch ${mutex_path}
	fi

	owner="${BLIB_COMMAND} ${BLIB_SUBCOMMAND}"
	if ${async}; then
		#
		# We try to get the mutex and hold it forever
		#
		escaped_command="$( str_escape "${CTL_INTERNAL} mutex holder ${forever} --mutex-name=${mutex_name} --owner=\"${owner}\" --async" )"
		       mutex_id="$( flock_wrlock --file ${mutex_path} --timeout ${timeout} --escaped-command="${escaped_command}" )"
		rc=$?
		if [ ${rc} -eq 0 ]; then
			# log_msg "${FUNCNAME}: got mutex_id: ${mutex_id}"
			echo ${mutex_id}
			return 0
		else
			log_msg "${FUNCNAME}: FAILED to get ${mutex_name}, rc = ${rc}"
			return ${rc}
		fi
	else
		#
		# We try to get the mutex while the command is running
		#
		escaped_command="$( str_escape "${CTL_INTERNAL} mutex holder --mutex-name=${mutex_name} --owner=\"${owner}\" --escaped-command=\"${escaped_command}\"" )"
		flock_wrlock --file ${mutex_path} --timeout ${timeout} --escaped-command="${escaped_command}"
		rc=$?

		#
		# the return code can be:
		# 1. const_status_flock_timeout - we couldn't get the mutex
		# 2. the command's return status - we had the mutex, ran the command an it exited
		#
		return ${rc}
	fi
}

function mutex_owner() {
	declare mutex_name="${1}"
	declare mutex_path=$( _mutex_name_to_path "${mutex_name}" )
	declare pid command stat

	if [ -r ${mutex_path} ]; then
		eval $(< ${mutex_path})
		kill -0 ${pid} &>/dev/null && stat=alive || stat=dead
		echo "mutex \"${mutex_name}\" is held by process id ${pid} [${stat}] for command: \"${command}\""
	fi
}

function mutex_unlock() {
	declare        arg="${1}"
	declare mutex_name=${arg%:*}
	declare mutex_path=$( _mutex_name_to_path "${mutex_name}" )
	declare pid command

	if [ -r "${mutex_path}" ]; then
		eval $(< ${mutex_path})
		kill -9 ${pid} &>/dev/null
		rm -f ${mutex_path}
		log_msg "${FUNCNAME}: unlocked mutex_name=\"${mutex_name}\", previously held by pid: ${pid} for command: \"${command}\""
	fi
}

function mutex_tryprune() {
	declare name="${1}"
	declare path=$( _mutex_name_to_path "${name}" )
	declare pid command

	if [ ! -e ${path} ]; then
		return
	fi
	eval $(< ${path})

	if [ "${pid}" ] && ! kill -0 ${pid} &>/dev/null; then
		rm -f ${path}
	fi
}

function mutex_register_for_cleanup() {
	declare mutex_id="${1}"

	_mutex_cleanup_list_="$( list_append "${mutex_id}" "${_mutex_cleanup_list_}" )"
}

function mutex_cleanup() {
	declare mutex_id

	for mutex_id in ${_mutex_cleanup_list_}; do
		mutex_unlock ${mutex_id}
	done
}

function mutex_init() {
    _mutex_dir=${BLIB_ETC}/mutexes
    _mutex_cleanup_list_=''
}
