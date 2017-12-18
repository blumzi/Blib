module_include log

function _caller() {
    local -a info

    command -v caller &>/dev/null || return

    info=( $( caller 1 ) )
    echo "[${info[2]#${BLIB_BIN}}:${info[0]} ${info[1]}] "
}

function error_fatal() {
    local opt status=$? message
    local opts=$( getopt -o 's:' --long status: -n "${prog}" -- "$@" )

    eval set -- "${opts}"

    while true; do
        case "${1}" in
        -s|--status)
            status=${2}
            shift 2
            ;;

        --)
            shift
            break
            ;;
        esac
    done
    message="${*}"

    log_msg --priority FATAL --stderr --caller="$(_caller)" "${message} (exit status: ${status})"
    if [ "${BLIB_PID}" ]; then
        module_include tmp mutex

        tmp_cleanup
        mutex_cleanup
        [ $$ -ne ${BLIB_PID} ] && kill -SIGTERM ${BLIB_PID}
    fi
    exit ${status}
}

function error_warning() {
    local warning="${*}"

    log_msg --priority WARNING --stderr --caller="$(_caller)" "${warning}"
}

function error_debug() {
    local message="${*}"

    log_msg --priority DEBUG --stderr --caller="$(_caller)" "${message}"
}

function error_msg() {
    local message="${*}"

    log_msg --priority INFO --stderr --caller="$(_caller)" "${message}"
}

function error_append() {
    local error="${1}"
    local errors="${2}"

    if [ "${errors}" ]; then
        echo "${errors}\n${error}"
    else
        echo "${error}"
    fi
}

function error_not_implemented_yet() {
    local what="${@}"

    error_fatal "${what}: Not implemented yet!"
}
