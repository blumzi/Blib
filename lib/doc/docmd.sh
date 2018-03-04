module_include str

_docmd_line_break="<br>\n"

function _docmd_escape_brackets() {
    local str="${@}"

    str="${str//[<>]/_}"
    echo "${str}"
}

function _docmd_escape_sharps() {
    local str="${@}"

    str="${str//${const_escaped_lsharp}/&lt;}"
    str="${str//${const_escaped_rsharp}/&gt;}"
    echo "${str}"
}

##
## @func    _docmd_indent
## @arg     <level> The indentation level
## @desc    Produces spaces according to the indentation level
## @out     Spaces
##
function _docmd_indent() {
    local -i level=${1}
    local indent="&nbsp;&nbsp;&nbsp;&nbsp;" i str

    for (( i = 0; i < level; i++ )); do
        str+="${indent}"
    done
    echo "${str}"
}

function _docmd_section() {
    local section="${1}"
    local str=''

    str="## $(str_toupper "${section}")\n\n"
    echo "${str}"
}

function docmd_format_command() {
    local command="${1}"
    local str

     str="$(_docmd_section command)"
    str+="$(_docmd_indent 1)${BLIB_COMMAND} ${command}${_docmd_line_break}"

    echo "${str}"
}

function docmd_format_file() {
    local file="${1}"
    local str

     str="$(_docmd_section file)"
    str+="$(_docmd_indent 1)${file}${_docmd_line_break}"

    echo "${str}"
}

function docmd_format_authors() {
    local -a authors="${@}"
    local str author

    [ "${authors}" ] || return

     str="$(_docmd_section authors)"
    str+="$(_docmd_indent 1)"
    for author in ${authors}; do
        str+="${author}, "
    done
    str="${str%, }"
    str+="${_docmd_line_break}"

    echo "${str}"
}

function docmd_format_description() {
    local -a descs="${@}"
    local str desc spaces min=1000 line

    [ "${descs}" ] || return

    str="$(_docmd_section description)"
    for desc in ${descs[@]}; do
        if [ "${desc}" = "${const_escaped_newline}" ]; then
            str+="<br>"
            continue
        fi
        spaces="${desc%%[^${const_escaped_space}]*}"
        if [ ${#spaces} -lt ${min} ]; then
            min=${#spaces}
        fi
    done

    for desc in ${descs[@]}; do
        line="$(_docmd_indent 1)${desc}"
        str+="${line:${min}}<br>"
    done

    echo "${str}"
}

##
## @func docmd_format_full_flag
## @arg <context> Either function or tool
## @arg <flag-info> 
## @out The formatted flag description suitable
## @out  either for a function or tool context
##
function docmd_format_full_flag() {
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
         str="$(_docmd_indent 2)"
        str+='*flag*'
        str+=" --_${flag_name}_"
        if [ "${flag_val}" ]; then
            str+="=_${flag_val}_"
        fi
        str+=" "
        if [ ${flag_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="$(str_unescape ${flag_desc})"
        ;;

    tool)
         str="$(_docmd_indent 1)"
        str+=" _${flag_name}_"
        if [ "${flag_val}" ]; then
            str+="=_${flag_val}_"
        fi
        str+=" "
        if [ ${flag_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="$(str_unescape ${flag_desc})"
        ;;
    esac

    echo "${str}${_docmd_line_break}"
}

##
## @func docmd_format_full_arg
## @arg <context> Either function or tool
## @arg <arg-info> 
## @out The formatted argument description suitable
## @out  either for a function or tool context
##
function docmd_format_full_arg() {
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
    arg_desc="$(_docmd_escape_brackets "${info[2]}")"

    case ${context} in
    function)
         str="$(_docmd_indent 2)"
        str+="*arg* _${arg_name}_    "
        if [ ${arg_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="$(str_unescape "${arg_desc}")"
        ;;

    tool)
         str="$(_docmd_indent 1)"
        str+=" _${arg_name}_"
        str+="   "
        if [ ${arg_type} = optional ]; then
            str+=" [opt] "
        fi
        str+="$(str_unescape ${arg_desc})"
        ;;
    esac

    echo "${str}${_docmd_line_break}"
}

function docmd_format_flags() {
    local -a flags="${@}"
    local str flag

    [ "${flags}" ] || return

    str="$(_docmd_section flags)"
    for flag in ${flags[@]}; do
        str+="$(docmd_format_full_flag tool "${flag}")"
    done

    echo "${str}"
}

function docmd_format_args() {
    local -a args="${@}"
    local str arg

    if [ ! "${args}" ]; then
        return
    fi

    str="$(_docmd_section args)"
    for arg in ${args[@]}; do
        str+="$(_docmd_full_arg_description tool "${arg}")"
    done

    echo "${str}"
}

function docmd_format_outputs() {
    local -a outputs="${@}"
    local str output

    [ "${outputs}" ] || return

    str="$(_docmd_section output)"
    for output in ${outputs[@]}; do
        doc+="$(_docmd_indent 1)${output}\n"
    done

    echo "${str}"
}

function docmd_format_exits() {
    local -a exits="${@}"
    local str e exit_code exit_reason

    [ "${exits}" ] || return

    str="$(_docmd_section "exit codes")"
    for e in ${exits[@]}; do
        set ${e/:/ }
        exit_code=${1}
        shift
        exit_reason="${*}"
        str+="$(printf "%s%-4s - %s" "$(_docmd_indent 1)" "${exit_code}" "${exit_reason}")\n"
    done

    echo "${str}"
}

function docmd_format_module_section() {
    local section="${1}"
    local    text="${2}"
    local str

    [ "${section}" = "name" ] && section="module name"
    str="$( _docmd_section "${section}" )"
    while [ "${text}" ]; do
        str+="$(_docmd_indent 1)${text%%\\n*}\n"
        if [[ "${text}" == *\\n* ]]; then
            text="${text#*\\n}"
        else
            text=""
        fi
    done
    str+="\n\n"

    echo "$(_docmd_escape_sharps "${str}")"
}

function _docmd_inline_flag_description() {
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
    arg_desc="$(_docmd_escape_brackets "${info[3]}")"

    str="${arg_name}"
    if [ "${arg_val}" ]; then
        str+="=_${arg_val}_"
    fi
    #str="_${str}_"

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

function _docmd_inline_arg_description() {
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
    arg_desc="$(_docmd_escape_brackets "${info[2]}")"

    str="${arg_name}"
    #str="$( str_color --underline white "${str}" )"
    str="_${str}_"

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

function docmd_format_module_function() {
    local        name="${1}"
    local       flags="${2}"
    local        args="${3}"
    local      stdout="${4}"
    local     returns="${5}"
    local     summary="${6}"
    local description="${7}"
    local str _flag _arg _out _ret _sum _desc

    # render the syntax line
    str="\n$(_docmd_indent 1)**${name}**"
    str+=" "
    if [ "${flags}" ]; then
        for _flag in ${flags}; do
            str+="$( _docmd_inline_flag_description "${_flag}" )"
            str+=" "
        done
    fi

    if [ "${args}" ]; then
        for _arg in ${args}; do
            str+="$( _docmd_inline_arg_description "${_arg}" )"
            str+=" "
        done
    fi
    str+=${_docmd_line_break}
    # end of syntax line
    #str+="\n<p>\n"

    if [ "${flags}" ]; then
        for _flag in ${flags}; do
            str+="$( docmd_format_full_flag function "${_flag}" )"
        done
    fi

    if [ "${args}" ]; then
        for _arg in ${args}; do
            str+="$( docmd_format_full_arg function "${_arg}" )"
        done
    fi

    if [ "${stdout}" ]; then
        for _out in ${stdout}; do
            str+="$(_docmd_indent 2)*out*   ${_out}"
        done
    fi

    if [ "${summary}" ]; then
        str+="$(_docmd_indent 2)${summary}"
    fi

    if [ "${description}" ]; then
        description="${description//${const_escaped_lsharp}/_}"
        description="${description//${const_escaped_rsharp}/_}"
        while [ "${description}" ]; do
            str+="$(_docmd_indent 2)${description%%\\n*}<br>"
            if [[ "${description}" == *\n* ]]; then
                description="${description#*\\n}"
            else
                description=""
            fi
        done
    fi

    #str+="\n</p>\n"
    echo "${str}${_docmd_line_break}"
}

function docmd_init() {
    #
    # Command rendering functions
    #
             doc_render_command=docmd_format_command       
                doc_render_file=docmd_format_file          
             doc_render_authors=docmd_format_authors       
         doc_render_description=docmd_format_description   
               doc_render_flags=docmd_format_flags         
                doc_render_args=docmd_format_args
             doc_render_outputs=docmd_format_outputs
               doc_render_exits=docmd_format_exits
            doc_render_full_arg=docmd_format_full_arg
           doc_render_full_flag=docmd_format_full_flag

    #
    # Module rendering functions
    #
      doc_render_module_section=docmd_format_module_section
     doc_render_module_function=docmd_format_module_function
}
