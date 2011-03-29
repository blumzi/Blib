#!/bin/bash

function _flock_common_() {
    declare timeout="--timeout 10"
    declare non_block file exclusive command
    declare opts=$( env POSIXLY_CORRECT=1 getopt -o 'c:,e,f:Nn' --long "command:,escaped-command:,exclusive,file:,no-timeout:,non-block,timeout:" -n "${prog}" -- "$@" )

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --escaped-command)
            command="$( str_unescape "${2}" )"
            shift 2
            ;;

        -c|--command)
            command="${2}"
            shift 2
            ;;

        -e|--exclusive)
            exclusive="--exclusive"
            shift 1
            ;;

        -f|--file)
            file="${2}"
            shift 2
            ;;

        -n|--non-block)
            non_block="--non-block"
            shift 1
            ;;

        -N|--no-timeout)
            timeout=""
            shift 2
            ;;

        -t|--timeout)
            timeout="--timeout ${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    if [ ! "${file}" ]; then
        return 1
    fi

    flock ${exclusive} ${timeout} ${non_block} --file ${file} --command "${command}"
}

function flock_rdlock() {
    _flock_common_ "${@}"
}

function flock_wrlock() {
    _flock_common_ --exclusive "${@}"
}
