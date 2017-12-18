module_include xml const misc list flock str tmp trace

function log_file_path() {
    echo /var/log/${BLIB_COMMAND}
}

function log_trace_file_path() {
        echo /var/log/${BLIB_COMMAND}.trace
}

function _log_prio2syslog() {
    local         prio="${1}"
    local log_facility=user

    case "${prio}" in
    FATAL)  echo "-p ${log_facility}.err"       ;;
    INFO)   echo "-p ${log_facility}.info"      ;;
    NOTICE) echo "-p ${log_facility}.notice"    ;;
    WARNING)echo "-p ${log_facility}.warning"   ;;
    DEBUG)  echo "-p ${log_facility}.debug"     ;;
    esac
}

function log_msg() {
    local opts=$( getopt -o 'c:oeflsp:t:' --long caller:,stdout,stderr,syslog,file,priority:,tag: -n "${prog}" -- "$@" )
    local   stdout=false
    local   stderr=false
    local   syslog=true
    local     file=false
    local priority=INFO
    local log_file=$( log_file_path )
    local now cmd tag caller entry tmp ssh_info trace="$(trace_latest)"

    eval set -- "${opts}"

    while true; do
        case "${1}" in
        -c|--caller)
            caller="${2}"
            shift 2
            ;;
        -o|--stdout)
            stdout=true
            shift 1
            ;;
        -e|--stderr)
            stderr=true
            shift 1
            ;;
        -f|--file)
            file=true
            shift 1
            ;;
        -l|--syslog)
            syslog=true
            shift 1
            ;;
        -p|--priority)
            priority=${2}
            shift 2
            ;;

        -t|--tag)
            tag="${2}"
            shift 2
            ;;

        --)
            shift
            break
            ;;
        esac
    done

    cmd="${BLIB_COMMAND}"
    if [[ "${cmd}" == *--password=* ]]; then
        local opt="$( shopt -p extglob)"

        shopt -s extglob
        cmd="${cmd/--password=+([^[:space:]])/--password=********}"
        ${opt}
    fi
    if [ !"${tag}" ]; then
        tag="${cmd}"
    fi

    tag+="${trace}"

    if [ "${#}" -gt 0 ]; then
        echo -e "${*}"
    elif ! misc_stdin_is_pipe; then
        #
        # We cannot call error_fatal, it would recurse calling log_message
        #
        echo "FATAL: ${FUNCNAME}: no arguments and stdin is not a pipe" >&2
        return 1
    else
        cat -
    fi | while read line; do
        if ${stdout}; then
            echo "${BLIB_COMMAND}: ${line}"
        fi

        if ${stderr}; then
            echo "${BLIB_COMMAND}: ${line}" >&2
        fi

        if ${syslog}; then
            echo "${line}" | logger -t "${tag}" $(_log_prio2syslog ${priority}) 
        fi

        if ${file}; then
            if [ ! -e ${log_file} ]; then
                touch ${log_file} && chmod 666 ${log_file}
            fi
            if [ -w ${log_file} ]; then
                entry="$(
                    xml_element "entry" "$(
                        xml_element "time" "$( time_now )"
                        xml_element "trans" "$(
                            if [ "${CTL_TRANS_PID}" ] && [ "${SSH_CONNECTION}" ]; then
                                ssh_info=( ${SSH_CONNECTION} )
                                xml_element "remote" \
                                    -a "$( xml_attribute "host"    "${ssh_info[0]}"       )" \
                                    -a "$( xml_attribute "command" "$( str_unpack "${CTL_TRANS_COMMAND}" )" )" \
                                    -a "$( xml_attribute "pid"     "${CTL_TRANS_PID}"     )" \
                                    ""
                            fi
                            if [ "${CTL_FROM_WATCHDOG}" ]; then
                                xml_element "local" \
                                    -a "$( xml_attribute from-watchdog true                )" \
                                    -a "$( xml_attribute "command" "${BLIB_COMMANDLINE}" )" \
                                    -a "$( xml_attribute "pid"     "${BLIB_PID}"         )" \
                                    ""
                            else
                                xml_element "local" \
                                    -a "$( xml_attribute "command" "${BLIB_COMMANDLINE}" )" \
                                    -a "$( xml_attribute "pid"     "${BLIB_PID}"         )" \
                                    ""
                            fi
                        )"
                        xml_element "command"  "${BLIB_COMMANDLINE}"
                        xml_element "priority" "${priority}"
                        xml_element "message"  "$( xml_esc "${caller}${line}" )"
                    )"
                )"
                tmp=$( tmp_mkfile "${FUNCNAME}.$$.${RANDOM}" )
                echo "${entry}" | xml_format > ${tmp}

                flock_wrlock --file=${log_file} --timeout=5 --escaped-command="cat ${tmp} >> ${log_file}"
                rm -f ${tmp}
            fi
        fi
    done
}

function log_trace() {
    local command="${1}"
    local rc="${2}"
    local trace_file=$( log_trace_file_path )
    local oldumask=$( umask -p )
    local opt="$( shopt -p extglob)"
 
    shopt -s extglob
    command="${command/--password=+([^[:space:]])/--password=********}"
    ${opt}

    mkdir -p $(dirname ${trace_file})
    umask 0
    xml_element trace "$(
        xml_element date        "$( time_now )"
        xml_element time        "$( date -u "+%s" )"
        xml_element uid         "$( id -u )"
        xml_element command     "${command/--notrace }"
        xml_element status      "${rc}"
    )" | xml fo -o >> ${trace_file}
    ${oldumask}
}

function log_savelogs() {
    local now=$( time_now )

    tail -1000 /var/log/messages > ${const_ss_tmp}/messages-${now}      # save some logs
    if [ -d ${const_ss_etc}/archive ]; then
        find ${const_ss_etc}/archive -type d -ctime +30 | xargs rm -rf
    fi

    return 0
}

function log_destinations() {
    local destinations="${1}"
    local dest new_destinations
    local log_destinations log_valid_destinations="stdout stderr syslog"


    if [ "${destinations}" ]; then
        for dest in ${destinations}; do
            if list_member "${dest}" "${log_valid_destinations}"; then
                new_destinations=$( list_append "${dest}" "${new_destinations}" )
            fi
        done
        log_destinations=$( list_sort -u "${new_destinations}" )
    else
        echo ${log_destinations}
    fi
}
