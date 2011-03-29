#!/bin/bash

##
## @module  xml
## @author  Arie Blumenzweig
## @desc    Various XML handling functions.  This module contains
## @desc     a set of wrappers around the excelent xmlstarlet tool used
## @desc     for parsing XML files.
## @desc
## @desc    Other functions produce XML elements and attributes in a standardized
## @desc     way.
##
module_include misc error flock str tmp

function xml_is_node() {
    local dbfile="${1}"
    local  xpath="${2}"

    xpath="${xpath#//}"         # discard leading //
    xpath="${xpath//\[*\]/}"    # discard qualifiers
    ${_xml_tool_} el ${dbfile} | grep -q "^${xpath}/"
}

function xml_delete_from_pipe() {
    local xpath="${1}"
    local   tmp=$( tmp_mkfile ${FUNCNAME}.${RANDOM} )
    local  tmp1=$( tmp_mkfile ${FUNCNAME}.${RANDOM}.1 )
    local rc

    cat - > ${tmp}
    if ! xml_valid --file=${tmp}; then
        rm -f ${tmp}
        return 1
    fi
    ${_xml_tool_} ed --omit-decl --delete "${xpath}" < ${tmp} > ${tmp1}
    rc=$?
    if [ ${rc} -ne 0 ]; then
        rm -f ${tmp} ${tmp1}
        return ${rc}
    elif ! xml_valid --file=${tmp1}; then
        rm -f ${tmp} ${tmp1}
        return 1
    fi
    cat ${tmp1}
    rm -f ${tmp} ${tmp1}
}

function xml_get_from_pipe() {
    local tmp=$( tmp_mkfile ${FUNCNAME}.${RANDOM} )

    cat - > ${tmp}
    xml_get ${tmp} "${@}"
    rm -f ${tmp}
}

##
## @func    xml_get
## @desc    Performs a select on an XML document
## @flag    [lock] First acquire a read lock on the document
## @flag    [value] An XPATH value expresion for the output
## @arg     <document> The XML document
## @arg     <xpath> An XPATH select expression
## @arg     [attr] An attribute name
## @out     The output of the XPATH selection (a tree, element or attribute or nothing).
## @ret     Status of validation
##
function xml_get() {
    local dbfile xpath attr tmp rc lock=false escaped_command value validate=false
    local opts=$( getopt -o 'l' --long 'lock,value:,validate' -n "${FUNCNAME}" -- "$@" )
    local dgbinfo

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --validate)
            validate=true
            shift 1
            ;;

        -l|--lock)
            lock=true
            shift 1
            ;;

        --value)
            value="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    dbfile="${1}"
     xpath="${2}"
      attr="${3}"
    
    dbginfo="caller: [$(_caller)], dbfile: [${dbfile}], xpath: [${xpath}], attr: [${attr}], value: [${value}]"

   if ${validate} && ! xml_valid --file=${dbfile}; then
       log_msg --priority=WARNING "${FUNCNAME}: aborted (file \"${dbfile}\" does not contain valid XML), dbg: ${dbginfo}."
       return 1
   fi

    if [ "${value}" ]; then
        if ${lock}; then
            escaped_command="$( str_escape "${_xml_tool_} sel -t -m \"${xpath}\" -v \"${value}\" -n ${dbfile}" )"
            flock_rdlock --file ${dbfile} --escaped-command="${escaped_command}"
        else
            ${_xml_tool_} sel -t -m "${xpath}" -v "${value}" -n ${dbfile}
        fi
        return
    fi

    if [[ "${attr}" == @* ]]; then
        if ${lock}; then
            escaped_command="$( str_escape "${_xml_tool_} sel -t -m \"${xpath}\" -v \"${attr}\" -n ${dbfile}" )"
            flock_rdlock --file ${dbfile} --escaped-command="${escaped_command}"
        else
            ${_xml_tool_} sel -t -m "${xpath}" -v "${attr}" -n ${dbfile}
        fi
        rc=$?
    else
        if xml_is_node ${dbfile} "${xpath}"; then
            if ${lock}; then
                escaped_command="$( str_escape "${_xml_tool_} sel -t -c \"${xpath}\" ${dbfile}" )"
                flock_rdlock --file ${dbfile} --escaped-command="${escaped_command}"
            else
                ${_xml_tool_} sel -t -c "${xpath}" ${dbfile}
            fi
            rc=$?
        else
            if ${lock}; then
                escaped_command="$( str_escape "${_xml_tool_} sel -t -m \"${xpath}\" -v \"text()\" -n ${dbfile}" )"
                flock_rdlock --file ${dbfile} --escaped-command="${escaped_command}"
            else
                ${_xml_tool_} sel -t -m "${xpath}" -v "text()" -n ${dbfile}
            fi
            rc=$?
        fi
    fi

    if [ "${tmp}" ]; then
        rm -f ${tmp}
    fi

    return ${rc}
}

##
## @func    xml_attribute
## @arg     <name> The attribute name
## @arg     <value> The attribute value
## @desc    Produces a canonical XML attribute.
## @desc    Example: xml_attribute name me => name="me"
## @out     The attribute
##
function xml_attribute() {
    local  name="${1}"
    local value="${2}"

    echo "${name}=\"${value}\""
}

##
## @func    xml_element
## @flag    [a=attribute] Specify attribute(s) for the element
## @arg     <value> Specify the element's value (may be empty)
## @desc    Produces a canonical XML element with the specified 
## @desc     attribute(s) and value.  For example:
## @desc
## @desc     xml_element interface -a "$(xml_attribute device eth20)" -a "$(xml_attribute addr 10.1.1.2/8)" ""
## @desc     
## @desc     produces:
## @desc  
## @desc        <interface device='eth20' addr='10.1.1.2/8' />
## @desc    
## @out     The element
##
function xml_element() {
    local name value attrs
    local optind=${OPTIND} opt

    name="${1}"
    shift
    OPTIND=1
    while getopts "a:" opt; do
        case ${opt} in
        a)
            attrs="${attrs} ${OPTARG}"
            ;;
        esac
    done
    shift $(( ${OPTIND} - 1 ))
    value="${*}"

    if [ "${attrs}" ]; then
        attrs=" ${attrs}"
    fi

    if [ "${value}" ]; then
        echo "<${name}${attrs}>${value}</${name}>"
    else
        echo "<${name}${attrs}/>"
    fi

    OPTIND=${optind}
}

function xml_set() {
    local opts=$( getopt -o 'l' --long lock -n "${prog}" -- "$@" )
    local attr attr_name
    local path type tmp tmpval tmp1
    local rc args lock
    local xmlfile xpath entity value
    local dbginfo

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        -l|--lock)
            lock=true
            shift 1
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    xmlfile="${1}"
      xpath="${2}"
     entity="${3}"
      value="${4}"
    dbginfo="caller: [$(_caller)], dbfile: [${dbfile}], xpath: [${xpath}], attr: [${attr}], value: [${value}]"

    if ! xml_valid --file=${xmlfile}; then
        log_msg --priority=WARNING "${FUNCNAME}: aborted (\"${xmlfile}\" is not a valid XML file), dbg: ${dbginfo}."
        return 1
    fi

    if [[ "${entity}" == @* ]]; then
        type=attr
    else
        type=elem
    fi
    path="${xpath}/${entity}"

    tmp=$( tmp_mkfile ${FUNCNAME} )
    path=${path#//}

    args="xpath=\"${xpath}\", entity=\"${entity}\", value=\"$( echo "${value}" | ${_xml_tool_} esc )\"."

    case "${type}" in
    elem)
        if ! xml_valid --text="<element>${value}</element>"; then
            log_msg --priority=WARNING "${FUNCNAME}: aborted (value is not XML valid). dbg: ${dbginfo}."
            return ${rc}
        fi

        cat ${xmlfile} | \
            ${_xml_tool_} ed --delete  "${xpath}/${entity}" | \
            ${_xml_tool_} ed --subnode "${xpath}" --type ${type} --name ${entity} --value "${value}" 
        rc=$?
        ;;
    attr)
        cat ${xmlfile} | \
            ${_xml_tool_} ed --delete  "${xpath}/${entity}" | \
            ${_xml_tool_} ed --subnode "${xpath}" --type ${type} --name ${entity#@} --value "${value}" 
        rc=$?
        ;;
    esac > ${tmp}
    
    if [ ${rc} -ne 0 ]; then
        log_msg --priority=WARNING "${FUNCNAME}: aborted (xml ed failed with rc: ${rc}). dbg: ${dbginfo}."
        return ${rc}
    elif ! xml_valid --file=${tmp}; then
        log_msg --priority=WARNING "${FUNCNAME}: aborted (resulting XML is invalid). dbg: ${dbginfo}."
        return 1
    fi

    tmp1=$( tmp_mkfile ${FUNCNAME}.1 )
    cat ${tmp} | ${_xml_tool_} unesc | xml_format > ${tmp1}

    if ${lock}; then
        flock_wrlock --file ${xmlfile} --command="cp ${tmp1} ${xmlfile}"
    else
        cp ${tmp1} ${xmlfile}
    fi
    rc=$?

    rm -f ${tmp} ${tmp1}
    return ${rc}
}

##
## @func    xml_valid
## @desc    Validates an XML document
## @ret     success or failure
## @flag    [pipe] Get the document from stdin
## @flag    [text=string] Validate the specified <text>
## @flag    [file=file] Validate the specified <file>
##
function xml_valid() {
    local tmp rc text file
    local got_text=false
    local     pipe=false
    local     opts=$( getopt -o '' --long "file:,pipe,text:" -n "${FUNCNAME}" -- "$@" )

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --pipe)
            pipe=true
            shift 1
            ;;
        --text)
            got_text=true
            text="${2}"
            shift 2
            ;;
        --file)
            file="${2}"
            shift 2
            ;;
        --)
            shift 1
            break
            ;;
        esac
    done

    tmp=$( tmp_mkfile ${FUNCNAME} )
    if ${pipe}; then
        if ! misc_stdin_is_pipe; then
            log_msg --priority=WARNING "${FUNCNAME}: got --pipe but stdin is not a pipe"
        fi
        cat - > ${tmp}
    elif ${got_text}; then
        if [ ! "${text}" ]; then
            log_msg --priority=WARNING "${FUNCNAME}: got --text but text is empty"
        fi
        echo -n "${text}" > ${tmp}
    elif [ "${file}" ]; then
        if [ ! -r ${file} ]; then
            log_msg --priority=WARNING "${FUNCNAME}: file \"${file}\" is not readable"
        elif [ ! -s ${file} ]; then
            log_msg --priority=WARNING "${FUNCNAME}: file \"${file}\" is empty"
        fi
        cp ${file} ${tmp}
    else
        rm -f ${tmp}
        return 1    # must get one of the above
    fi

    ${_xml_tool_} val ${tmp} &>/dev/null
    rc=$?
    rm -f ${tmp}
    return ${rc}
}

##
## @func    xml_comment
## @arg     <line> A comment line.  May be repeated.
## @desc    Produces a canonical single- or multiple-line XML comment.
## @out     The comment
##
function xml_comment() {
    local -a lines
    local nlines

    for line in "${@}"; do
            lines[${#lines[*]}]="${line}"
    done

    nlines=$(
            for line in "${lines[@]}"; do
                    echo -e "${line}"
            done | wc -l
    )

    if [ ${nlines} -gt 1 ]; then
            echo '<!--'
            for line in "${lines[@]}"; do
                    echo -e "${line}"
            done | sed 's;^;  - ;'
            echo '  -->'
    else
            echo '<!-- '${lines[@]}' -->'
    fi
}

function xml_format() {
    local cmd="${_xml_tool_} format --omit-decl --indent-spaces 2"

    if [ "${#}" -gt 0 ]; then
        echo "${*}" | ${cmd}
    elif ! misc_stdin_is_pipe; then
        error_fatal "${FUNCNAME}: internal error: no args and stdin is not a pipe"
    else
        ${cmd}
    fi
}

function xml_esc() {
    local cmd="${_xml_tool_} esc"

    if [ "${#}" -gt 0 ]; then
        echo "${*}" | ${cmd} 2>/dev/null
    elif ! misc_stdin_is_pipe; then
        error_fatal "${FUNCNAME}: internal error: no args and stdin is not a pipe"
    else
        ${cmd} 2>/dev/null
    fi
}

function xml_unesc() {
    local cmd="${_xml_tool_} unesc"

    if [ "${#}" -gt 0 ]; then
        echo "${*}" | ${cmd} 2>/dev/null
    elif ! misc_stdin_is_pipe; then
        error_fatal "${FUNCNAME}: internal error: no args and stdin is not a pipe"
    else
        ${cmd} 2>/dev/null
    fi
}

##
## @func    xml_version
## @desc    Produces the canonical XML version (1.0) line
##
function xml_version() {
    echo "<?xml version="1.0"?>"
}

function xml_init() {
    _xml_tool_="xmlstarlet"
}
