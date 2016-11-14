#!/bin/bash

function misc_password() {
    declare prompt="${1}"
    declare pass

    read -p "${prompt}" -s pass
    echo >&2
    echo ${pass}
}

function misc_have_subcommand() {
    declare command="${*}"

    command="$( echo "${command}" | sed -e 's;[[:space:]];/;g' )"
	for dir in ${BLIB_PATH//:/ }; do
			[ -x ${dir}/bin/${command} ] && return 0
	done
	return 1
}

function misc_stdin_is_pipe() {
    [[ "$(file -L /dev/stdin 2>/dev/null)" == *fifo* ]] && return 0 || return 1
}

function misc_deref() {
    declare path="${1}"

    readlink -f ${path}
}
