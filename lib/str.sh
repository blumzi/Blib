#!/bin/bash

_str_compactor_="@"

function str_compact() {
    local value="${1}"
    local restoreopt=$( shopt -p extglob )

    shopt -s extglob
    echo "${value//+([[:space:]])/${_str_compactor_}}"
    eval ${restoreopt}
}

function str_uncompact() {
    local value="${1}"

    echo "${value//${_str_compactor_}/ }"
}

function str_trim() {
    local str="${1}"

    if [ "${str}" ]; then
        echo "${str}" | sed -e 's;^[[:space:]]*;;' -e 's;[[:space:]]*$;;'
    fi
}

function str_print_var() {
    local   var="${1}"
    local   val="${2}"
    local extra="${3}"
    local line

    line="$(printf "%-30s %s\n" "${var}" "${val}")"
    [ "${extra}" ] && line+=" ${extra}"

    echo "${line}"
}

function str_print2() {
    local   var="${1}"
    local   val="${2}"
    local extra="${3}"

    printf "%-30s %-10s %s\n" "${var}" "${val}" "${extra}"
}

function str_squote() {
    local str="${1}"

    if [[ "${str}" == *[[:space:]]* ]]; then
        str="'${str}'"
    fi
    echo "${str}"
}

function str_quote() {
    local str="${1}"

    if [[ "${str}" == *[[:space:]]* ]]; then
        str="\"${str}\""
    fi
    echo "${str}"
}

function str_unquote() {
    local str="${1}"

    if [[ "${str}" == [\"\']*[\"\'] ]]; then
        echo "${str:2:-1}"
    else
        echo "${str}"
    fi
}

function str_bashify() {
    local str="${1}"

    echo "${str//-/_}"
}

function str_tolower() {
    local str="${1}"

    echo ${str} | tr '[A-Z]' '[a-z]'
}

function str_toupper() {
    local str="${1}"

    echo ${str} | tr '[a-z]' '[A-Z]'
}

function str_str2boolean() {
    local str="${1}"

    case "${str}" in
    0|[Ff]alse|[Nn]o|[Nn]|[Ff]|[Oo]ff|OFF)
        echo false
        ;;
    1|[Tt]rue|[Yy]es|[Yy]|[Tt]|[Oo]n|ON)
        echo true
        ;;
    *)
        return 1
    esac
}

function str_encode() {
    local clear="${1}"

    echo "${clear}" | openssl enc -base64 
}

function str_decode() {
    local encoded="${1}"

    echo "${encoded}" | openssl enc -d -base64
}

function str_pack() {
    local clear="${1}"
    echo "${clear}" | gzip -q -f -c | openssl enc -a | tr '\012' ':'
}

function str_unpack() {
    local packed="${1}"

    if [ "${packed}" ]; then
        echo "${packed}" | tr ':' '\012' | openssl enc -a -d | gunzip -q -f -c
    fi
}

function str_escape() {
    local str="${1}"

    echo -n "${str}" | tr   "${const_space}${const_tab}${const_quote}${const_bquote}${const_dquote}${const_newline}${const_dollar}${const_lpar}${const_rpar}${const_lbrkt}${const_rbrkt}" \
                "${const_escaped_space}${const_escaped_tab}${const_escaped_quote}${const_escaped_bquote}${const_escaped_dquote}${const_escaped_newline}${const_escaped_dollar}${const_escaped_lpar}${const_escaped_rpar}${const_escaped_lbrkt}${const_escaped_rbrkt}"
}

function str_unescape() {
    local str="${1}"

    echo -n "${str}" | tr   "${const_escaped_space}${const_escaped_tab}${const_escaped_quote}${const_escaped_dquote}${const_escaped_bquote}${const_escaped_newline}${const_escaped_dollar}${const_escaped_lpar}${const_escaped_rpar}${const_escaped_lbrkt}${const_escaped_rbrkt}" \
                "${const_space}${const_tab}${const_quote}${const_dquote}${const_bquote}${const_newline}${const_dollar}${const_lpar}${const_rpar}${const_lbrkt}${const_rbrkt}"
}

function str_hex_dump() {
    local str="${1}"

    echo -n "${str}" | od -w1024 -t x1 | sed 's;^.......;;'
}

function str_decomment() {
    local files

    if [ ${#} -gt 0 ]; then
        files="${@}"
    elif ! misc_stdin_is_pipe; then
        return
    else
        files="-"
    fi

    cat ${files} | sed -e 's;[[:space:]]*#.*;;' -e '/^[[:space:]]*$/d'
}

#
# See man terminfo(5)
#
_str_index_black=0
_str_index_red=1
_str_index_green=2
_str_index_yellow=3
_str_index_blue=4
_str_index_magenta=5
_str_index_cyan=6
_str_index_white=7

_str_color_seq=()
_str_color_blink=''
_str_color_bold=''
_str_color_underline=''
_str_color_inverse=''

function str_color() {
    local opts=$( getopt -o '' --long "blink,bold,underline,inverse" -n "${FUNCNAME}" -- "$@" )
    local index bold=false underline=true inverse=false sequence

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --inverse)
            inverse=true
            shift 1
            if [ ! "${_str_color_inverse}" ]; then
                _str_color_inverse="$(tput smso)"
            fi
            sequence+="${_str_color_inverse}"
            ;;

        --blink)
            blink=true
            shift 1
            if [ ! "${_str_color_blink}" ]; then
                _str_color_blink="$(tput blink)"
            fi
            sequence+="${_str_color_blink}"
            ;;

        --bold)
            bold=true
            shift 1
            if [ ! "${_str_color_bold}" ]; then
                _str_color_bold="$(tput bold)"
            fi
            sequence+="${_str_color_bold}"
            ;;

        --underline)
            underline=true
            shift 1
            if [ ! "${_str_color_underline}" ]; then
                _str_color_underline="$(tput smul)"
            fi
            sequence+="${_str_color_underline}"
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    case "${1}" in
    black|red|green|yellow|blue|magenta|cyan|white)
        index="_str_index_${1}"
        index=${!index}
        ;;

    0|1|2|3|4|5|6|7)
        index=${1}
        ;;

    *)
        shift 1
        echo "${sequence}${*}${_str_color_normal}"
        return
        ;;
    esac
        
    shift 1
    text="${*}"
    if [ ! "${_str_color_seq[${index}]}" ]; then
        _str_color_seq[${index}]="$(tput setaf ${index})"
    fi
    sequence+="${_str_color_seq[${index}]}${text}${_str_color_normal}"
    echo "${sequence}"
}

function str_init() {
    _str_color_normal="$(tput sgr0)"

    module_include const
}
