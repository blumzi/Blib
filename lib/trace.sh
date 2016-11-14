#!/bin/bash

module_include log const xml time

#
# Traces help tracing a chain of events.  
#
# The trace is maintained in the BLIB_TRACE environment variable.  A trace element
#  is actually a tuple containing:
#   - the host where the event occured
#   - the process ID 
#   - the trace ID within the process
#
# The BLIB_TRACE is exported via ssh sessions
#

function _trace_decorate_() {
    local trace_id="${1}"

    echo "[[${trace_id//${const_trace_internal_sep}/:}]]"
}

function trace_start() {
    local caller_msg="${*}"
    local host=${HOSTNAME}
    local prev="${BLIB_TRACE##*${const_trace_sep}}"
    local new caller _caller

    if [ "${prev}" ]; then
        local -a info=( ${prev//${const_trace_internal_sep}/ } )

        if [ "${info[0]}" = ${host} ] && [ "${info[1]}" = ${$} ]; then
            # same host, same process -> bump tid
            new="${host}${const_trace_internal_sep}${$}${const_trace_internal_sep}$(( ${info[2]} + 1 ))"
        else
            # host or process have changed, start a new one
            new="${host}${const_trace_internal_sep}${$}${const_trace_internal_sep}0"
        fi
    else
        # no previous, start a new one
        new="${host}${const_trace_internal_sep}${$}${const_trace_internal_sep}0"
    fi

    if [ "${BLIB_TRACE}" ]; then
        export BLIB_TRACE+="${const_trace_sep}${new}"
    else
        export BLIB_TRACE="${new}"
    fi

    if command -v caller &>/dev/null; then
        local info=( $( caller 0 ) )

        _caller="${info[2]#${BLIB_BIN}}:${info[0]} ${info[1]}"
        caller="--caller=\"[${_caller}]\""
    fi
    log_msg --syslog "${caller}" "${caller_msg}"

    new="$( echo "${new}" | tr "${const_trace_internal_sep}" ':' )"
    xml_element 'entry' \
        -a "$(xml_attribute 'id'        "${new}"                )" \
        -a "$(xml_attribute 'time'      "$(time_now_seconds)"   )" \
        -a "$(xml_attribute 'action'    "start"                 )" \
        -a "$(xml_attribute 'caller'    "${_caller}"            )" \
        -a "$(xml_attribute 'message'   "${caller_msg}"         )" \
        "" >> ${_trace_file}
}

function trace_end() {
    local caller _caller latest

    if command -v caller &>/dev/null; then
        local info=( $( caller 0 ) )

        _caller="${info[2]#${BLIB_BIN}}:${info[0]} ${info[1]}"
        caller="--caller=\"[${_caller}]\""
    fi

    latest="${BLIB_TRACE##*${const_trace_sep}}"

    export BLIB_TRACE="${BLIB_TRACE%${const_trace_sep}*}"
    log_msg --syslog "${caller}" "${FUNCNAME}"

    latest="$( echo "${latest}" | tr "${const_trace_internal_sep}" ':' )"
    xml_element 'entry' \
        -a "$(xml_attribute 'id'        "${latest}"             )" \
        -a "$(xml_attribute 'time'      "$(time_now_seconds)"   )" \
        -a "$(xml_attribute 'action'    "end"                   )" \
        -a "$(xml_attribute 'caller'    "${_caller}"            )" \
        "" >> ${_trace_file}
}

function trace_latest() {
    _trace_decorate_ "${BLIB_TRACE##*${const_trace_sep}}"
}

function trace_previous() {
    local str="${BLIB_TRACE%${const_trace_sep}*}"

    _trace_decorate_ "${str##*${const_trace_sep}}"
}

function trace_init() {
	if [ -w /var/log/blib-trace.xml ]; then
		_trace_file=/var/log/blib-trace.xml
	else
		mkdir -p ${HOME}/.blib
		_trace_file=${HOME}/.blib/trace.xml
	fi
}
