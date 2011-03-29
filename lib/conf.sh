#!/bin/bash

##
## @module  conf
## @desc    Handles variable=value type lines in bash configuration files.
## @desc    Ignores any other lines.
##

##
## @func    conf_getvar
## @arg     <file> The configuration file
## @arg     <var>  The variable name
## @desc    Gets the value of <var> from <file>
## @out     The value, if found.
## @ret     succes if the variable was found, failure otherwise
##
function conf_getvar() {
    local file="${1}"
    local  var="${2}"
    local line

    #
    # Read lines, getting rid of comments and leading spaces
    #
    while read line; do
        line="${line%%#*}"
        line="${line#[[:space:]]}"
        if [[ "${line}" == ${var}=* ]]; then
            echo "${line#*=}"
            return 0
        fi
    done < ${file}

    return 1
}

##
## @func    conf_setvar
## @arg     <file> The configuration file
## @arg     <var>  The variable name
## @arg     <val>  The variable value
## @desc    Adds a <var>=<val> line to <file>.  Previous values are discarded first.
##
function conf_setvar() {
    local file="${1}"
    local  var="${2}"
    local  val="${3}"
    local  tmp=/tmp/${FUNCNAME}.$$

    (
        grep -v "^[[:space:]]*${var}=" ${file}
        echo "${var}=${val}"
    ) < ${file} > ${tmp}
    mv -f ${tmp} ${file}
}
