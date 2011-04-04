#!/bin/bash

module_include str

##
## @func    _doctext_indent
## @arg     <level> The indentation level
## @desc    Produces spaces according to the indentation level
## @out     Spaces
##
function _doctext_indent() {
    local -i level=${1}
    local indent="   " i str

    for (( i = 0; i < level; i++ )); do
        str+="${indent}"
    done
    echo "${str}"
}

function _doctext_section() {
    local section="${1}"

    echo "\n$(str_color --bold white "$(str_toupper "${section}")")\n"
}

function doctext_format_command() {
    local command="${1}"
    local str

     str="$(_doctext_section command)"
    str+="$(_doctext_indent 1)${BLIB_COMMAND} ${command}"
    str+="\n"

    echo "${str}"
}

function doctext_format_file() {
    local file="${1}"
    local str

     str="$(_doctext_section file)"
    str+="$(_doctext_indent 1)${file}"
    str+="\n"

    echo "${str}"
}

function doctext_format_authors() {
    local -a authors="${@}"
    local str author

    [ "${authors}" ] || return

     str="$(_doctext_section authors)"
    str+="$(_doctext_indent 1)"
    for author in ${authors}; do
        str+="${author}, "
    done
    str="${str%, }"
    str+="\n"

    echo "${str}"
}

function doctext_format_description() {
    local -a descs="${@}"
    local str desc

    [ "${descs}" ] || return

    str="$(_doctext_section description)"
    for desc in ${descs[@]}; do
        str+="$(_doctext_indent 1)${desc}\n"
    done

    echo "${str}"
}

##
## @func doctext_format_full_flag
## @arg <context> Either function or tool
## @arg <flag-info> 
## @out The formatted flag description suitable
## @out  either for a function or tool context
##
function doctext_format_full_flag() {
    local   context="${1}"
    local flag_info="${2}"
    local -a info
    local flag_name flag_type flag_desc flag_val str
    local ifs="${IFS}"

    [ "${flag_info}" ] || return

    IFS="${_doc_flag_separator}"
    info=( ${flag_info} )
    IFS="${ifs}"

    flag_name="${info[0]}"
    flag_type="${info[1]}"
     flag_val="${info[2]}"
    flag_desc="${info[3]}"

    case ${context} in
    function)
         str="$(_doctext_indent 2)"
        str+="$(str_color --bold white "flag") "
        str+="--$(str_color --underline white "${flag_name}")"
        if [ "${flag_val}" ]; then
            str+="="
            str+="$(str_color --bold white "${flag_val}")"
        fi
        str+=" "
        if [ ${flag_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="${flag_desc}"
        str+="\n"
        ;;

    tool)
         str="$(_doctext_indent 1)"
        str+="--$(str_color --underline white "${flag_name}")"
        if [ "${flag_val}" ]; then
            str+="="
            str+="$(str_color --bold white "${flag_val}")"
        fi
        str+=" "
        if [ ${flag_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="${flag_desc}"
        ;;
    esac

    echo "${str}"
}

##
## @func doctext_format_full_arg
## @arg <context> Either function or tool
## @arg <arg-info> 
## @out The formatted argument description suitable
## @out  either for a function or tool context
##
function doctext_format_full_arg() {
    local  context="${1}"
    local arg_info="${2}"
    local -a info
    local arg_name arg_type arg_desc arg_val str
    local ifs="${IFS}"

    [ "${arg_info}" ] || return

    IFS="${_doc_flag_separator}"
    info=( ${arg_info} )
    IFS="${ifs}"

    arg_name="${info[0]}"
    arg_type="${info[1]}"
    arg_desc="${info[2]}"

    case ${context} in
    function)
         str="$(_doctext_indent 2)"
        str+="$(str_color --bold white "arg")  "
        str+="$(str_color --underline white "${arg_name}")"
        str+="   "
        if [ ${arg_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="${arg_desc}"
        str+="\n"
        ;;

    tool)
         str="$(_doctext_indent 1)"
        str+="$(str_color --underline white "${arg_name}")"
        str+="   "
        if [ ${arg_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="${arg_desc}"
        str+="\n"
        ;;
    esac

    echo "${str}"
}

function doctext_format_flags() {
    local -a flags="${@}"
    local str flag

    [ "${flags}" ] || return

    str="$(_doctext_section flags)"
    for flag in ${flags[@]}; do
        str+="$(doctext_format_full_flag tool "${flag}")\n"
    done

    echo "${str}"
}

function doctext_format_args() {
    local -a args="${@}"
    local str arg

    if [ ! "${args}" ]; then
        return
    fi

    str="$(_doctext_section args)"
    for flag in ${flags[@]}; do
        str+="$(_doctext_full_arg_description tool "${flag}")\n"
    done

    echo "${str}"
}

function doctext_format_outputs() {
    local -a outputs="${@}"
    local str output

    [ "${outputs}" ] || return

    str="$(_doctext_section output)"
    for output in ${outputs[@]}; do
        doc+="$(_doctext_indent 1)${output}\n"
    done

    echo "${str}"
}

function doctext_format_exits() {
    local -a exits="${@}"
    local str e exit_code exit_reason

    [ "${exits}" ] || return

    str="$(_doctext_section "exit codes")"
    for e in ${exits[@]}; do
        set ${e/:/ }
        exit_code=${1}
        shift
        exit_reason="${*}"
        str+="$(printf "%s%-4s - %s" "$(_doctext_indent 1)" "${exit_code}" "${exit_reason}")\n"
    done

    echo "${str}"
}

function doctext_format_module_section() {
    local section="${1}"
    local    text="${2}"
    local str

    [ "${section}" = "name" ] && section="module name"
    str="$( _doctext_section "${section}" )"
    while [ "${text}" ]; do
        str+="$(_doctext_indent 1)${text%%\\n*}\n"
        if [[ "${text}" == *\\n* ]]; then
            text="${text#*\\n}"
        else
            text=""
        fi
    done

    echo "${str}"
}

function _doctext_inline_flag_description() {
    local arg_info="${1}"
    local -a info
    local arg_name arg_type arg_desc arg_val str
    local ifs="${IFS}"

    [ "${arg_info}" ] || return

    IFS="${_doc_flag_separator}"
    info=( ${arg_info} )
    IFS="${ifs}"

    arg_name="${info[0]}"
    arg_type="${info[1]}"
     arg_val="${info[2]}"
    arg_desc="${info[3]}"

    str="${arg_name}"
    if [ "${arg_val}" ]; then
        str+="=<${arg_val}>"
    fi
    str="$( str_color --underline white "${str}" )"

    case ${arg_type} in
    mandatory)
        str="${_doc_mandatory_deco:0:1}--${str}${_doc_mandatory_deco:1:1}"
        ;;

    optional)
        str="${_doc_optional_deco:0:1}--${str}${_doc_optional_deco:1:1}"
        ;;
    esac

    echo "${str}"
}

function _doctext_inline_arg_description() {
    local arg_info="${1}"
    local -a info
    local arg_name arg_type arg_desc arg_val str
    local ifs="${IFS}"

    [ "${arg_info}" ] || return

    IFS="${_doc_flag_separator}"
    info=( ${arg_info} )
    IFS="${ifs}"

    arg_name="${info[0]}"
    arg_type="${info[1]}"
    arg_desc="${info[2]}"

    str="${arg_name}"
    str="$( str_color --underline white "${str}" )"

    case ${arg_type} in
    mandatory)
        str="${_doc_mandatory_deco:0:1}${str}${_doc_mandatory_deco:1:1}"
        ;;

    optional)
        str="${_doc_optional_deco:0:1}${str}${_doc_optional_deco:1:1}"
        ;;
    esac

    echo "${str}"
}

function doctext_format_module_function() {
    local        name="${1}"
    local       flags="${2}"
    local        args="${3}"
    local      stdout="${4}"
    local     returns="${5}"
    local     summary="${6}"
    local description="${7}"
    local str _flag _arg _out _ret _sum _desc

    # render the syntax line
    str="\n$(_doctext_indent 1)$(str_color --bold white "${name}")"
    str+=" "
    if [ "${flags}" ]; then
        for _flag in ${flags}; do
            str+="$( _doctext_inline_flag_description "${_flag}" )"
            str+=" "
        done
    fi

    if [ "${args}" ]; then
        for _arg in ${args}; do
            str+="$( _doctext_inline_arg_description "${_arg}" )"
            str+=" "
        done
    fi
    # end of syntax line

    if [ "${flags}" ]; then
        str+='\n'
        for _flag in ${flags}; do
            str+="$( doctext_format_full_flag function "${_flag}" )"
        done
    fi

    if [ "${args}" ]; then
        str+='\n'
        for _arg in ${args}; do
            str+="$( doctext_format_full_arg function "${_arg}" )"
        done
    fi

    if [ "${stdout}" ]; then
        for _out in ${stdout}; do
            str+="$(_doctext_indent 2)$(str_color --bold white 'out')   "${_out}""
            str+='\n'
        done
    fi

    if [ "${summary}" ]; then
        str+="$(_doctext_indent 2)${summary}"
    fi

    if [ "${description}" ]; then
        while [ "${description}" ]; do
            str+="$(_doctext_indent 2)${description%%\\n*}\n"
            if [[ "${description}" == *\n* ]]; then
                description="${description#*\\n}"
            else
                description=""
            fi
        done
    fi

    echo "${str}"
}

function doctext_init() {
    #
    # Command rendering functions
    #
             doc_render_command=doctext_format_command       
                doc_render_file=doctext_format_file          
             doc_render_authors=doctext_format_authors       
         doc_render_description=doctext_format_description   
               doc_render_flags=doctext_format_flags         
                doc_render_args=doctext_format_args
             doc_render_outputs=doctext_format_outputs
               doc_render_exits=doctext_format_exits
            doc_render_full_arg=doctext_format_full_arg
           doc_render_full_flag=doctext_format_full_flag

    #
    # Module rendering functions
    #
      doc_render_module_section=doctext_format_module_section
     doc_render_module_function=doctext_format_module_function
}
