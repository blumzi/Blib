#!/bin/bash

function time_now_seconds() {
    date +%s
}

function time_now() {
    date +%Y-%h-%d.%T
}

function time_timeout() {
    local opts=$( getopt -o 'c:hs:m:u:' --long seconds:,micros:,command: -n "${prog}" -- "$@" )
    local secs=1 usecs=1000 cmd
    local worker_pid worker_status worker_pid_file
    local killer_pid sleeper period

    eval set -- "${opts}"

    while true; do
        case "${1}" in
        -c|--command)
            cmd="${2}"
            shift 2
            ;;

        -s|--seconds)
            sleeper=sleep
             period=${2}
            shift 2
            ;;

        -m|-u|--micros)
            sleeper=usleep
             period=${2}
            shift 2
            ;;
        --)
            shift 1
            break
            ;;

        esac
    done

    if [ ! "${sleeper}" ]; then
        sleeper=sleep
         period=1
    fi

    bash -c "${cmd}" &
    exec 2>-
    worker_pid=$!

    bash -c "${sleeper} ${period}; kill ${worker_pid} &>/dev/null" &
    killer_pid=$!

    wait ${worker_pid}
    worker_status=$?
    kill ${killer_pid} &>/dev/null

    if [ ${worker_status} = $(( 128 + 15 )) ]; then     # on signal the status is 128 + the signal number (15 == TERM)
        module_include const

        return ${const_command_timedout}
    else
        return ${worker_status}
    fi
}
