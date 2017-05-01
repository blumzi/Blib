#!/bin/bash

module_include list

command_remote_host=
command_remote_user=
command_remote_identity=

function command_remote_set() {
    local opts=$( getopt -o '' --long "host:,user:,identity:" -n "${FUNCNAME}" -- "$@" )
    local host=localhost user=${USER} command
    local status identity

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --identity)
            command_remote_identity="${2}"
            shift 2
            ;;

        --host)
            command_remote_host="${2}"
            shift 2
            ;;

        --user)
            command_remote_user="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done
}

function command_getopts() {
    local file=${1}
    local opts

    opts="$(grep BLIB_OPTS= ${file})"
    if [ "${opts}" ]; then
        opts="$(echo "${opts}" | sed \
            -e 's;.*--long.; ;' \
            -e 's;";;g' \
            -e "s;';;g" \
            -e 's; -n.*;;' \
            -e 's;:;=;g' \
            -e 's;,; ;g' \
            -e 's;^[[:space:]]*;;')"

        if [ "${opts}" ]; then
            opts="$(list_sort "${opts}")"
            echo "  --${opts// /  --}"
        fi
    fi
}

function command_path_lookup() {
    local path="${*}"
    local dir

    path="${path// //}"
    for dir in ${BLIB_PATH//:/ }; do
        if [ -e ${dir}/bin/${path} ]; then
            echo ${dir}/bin/${path}
            return 0
        fi
    done
    return 1
}

function command_parent() {
    declare cmdline=/proc/${PPID}/cmd

    if [ -r ${cmdline} ]; then
        tr '\0' ' ' < ${cmdline}
    fi
}

##
## @func    command_local
## @arg     <command+args> The command and its arguments
## @desc    Runs a command localy
## @ret     exit status of the command
## @out     standard output of the command
## @end
##
function command_local() {
    local cmd="${*}"
    local status

    ${cmd}
    status=$?
    # log?
    return ${status}
}

##
## @func    command_remote
## @flag    <host=(name|addr)> Host name or IP address (default: localhost)
## @flag    [user=user-name] The user to use (default: current user)
## @flag    [identity=identity-file] The identity to use (default: no identity)
## @arg     <command+args> The command and its arguments
## @desc    Runs a command remotely via SSH
## @ret     exit status of the command
## @out     standard output of the command
## @end
##
function command_remote() {
    local opts=$( getopt -o '' --long "host:,user:,identity:" -n "${FUNCNAME}" -- "$@" )
    local host=localhost user=${USER} command
    local status identity

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --identity)
            identity="${2}"
            shift 2
            ;;

        --host)
            host="${2}"
            shift 2
            ;;

        --user)
            user="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done
    command="${@}"

    # TBD: Send the BLIB_TRACE env. var.
    if [ ! "${identity}" ] && [ "${command_remote_identity}" ]; then
        identity="${command_remote_identity}"
    fi

    if [ ! "${user}" ] && [ "${command_remote_user}" ]; then
        user="${command_remote_user}"
    fi

    if [ ! "${host}" ] && [ "${command_remote_host}" ]; then
        host="${command_remote_host}"
    fi

    ssh ${identity:+-i ${identity}} ${user:+${user}@}${host} ${cmd}
    status=$?

    # log?
    return ${status}
}
