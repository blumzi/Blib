module_include str

##
## @func    _doc_indent
## @arg     <level> The indentation level
## @desc    Produces spaces according to the indentation level
## @out     Spaces
##
function _doc_indent() {
    local -i level=${1}
    local indent="   " i str

    for (( i = 0; i < level; i++ )); do
        str+="${indent}"
    done
    echo "${str}"
}

function _doc_flag_unpack() {
    local str="${*}"

    echo "${str//${_doc_flag_separator}/ }"
}

function _doc_flag_pack() {
    local str arg

    for arg in "${@}"; do
        str+="${arg}${_doc_flag_separator}"
    done
    echo "${str%${_doc_flag_separator}}"
}

function _doc_inline_arg_description() {
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

function _doc_inline_flag_description() {
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

##
## @func _doc_full_flag_description
## @arg <context> Either function or tool
## @arg <flag-info> 
## @out The formatted flag description suitable
## @out  either for a function or tool context
##
function _doc_full_flag_description() {
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
         str="$(_doc_indent 2)"
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
         str="$(_doc_indent 1)"
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
    esac

    echo "${str}"
}

##
## @func _doc_full_arg_description
## @arg <context> Either function or tool
## @arg <arg-info> 
## @out The formatted argument description suitable
## @out  either for a function or tool context
##
function _doc_full_arg_description() {
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
         str="$(_doc_indent 2)"
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
         str="$(_doc_indent 1)"
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

function _doc_section() {
    local section="${1}"

    echo "\n$(str_color --bold white "$(str_toupper "${section}")")\n"
}

function _doc_parse_flag() {
    local input="${1}"

    ##
    ## @flag:    <flag-name=flag-value> flag-description (mandatory flag)
    ## @flag:    [flag-name=flag-value] flag-description (optional  flag)
    ##
    local flag_type flag_name flag_value flag_desc
    local  opt_flag_pattern_with_value="\[([^=]*)=([^]]*)\]"
    local             opt_flag_pattern="\[([^]]*)\]"
    local mand_flag_pattern_with_value="<([^=]*)=([^>]*)>"
    local            mand_flag_pattern="<([^>]*)>"

    if  [[ "${input}" =~ ${mand_flag_pattern_with_value} ]] ||
        [[ "${input}" =~ ${mand_flag_pattern} ]]; then
         flag_type=mandatory
    elif [[ "${input}" =~ ${opt_flag_pattern_with_value} ]] ||
         [[ "${input}" =~ ${opt_flag_pattern} ]]; then
         flag_type=optional
    fi

     flag_name="${BASH_REMATCH[1]}"
    flag_value="${BASH_REMATCH[2]}"
     flag_desc="$(str_trim "${input:${#BASH_REMATCH[0]}}")"

    _doc_flag_pack "${flag_name}" "${flag_type}" "${flag_value}" "$(str_escape "${flag_desc}")"
}

function _doc_parse_arg() {
    local input="${1}"

    ##
    ## @arg:    <arg-name> arg-description (mandatory arg)
    ## @arg:    [arg-name] arg-description (optional  arg)
    ##
    local arg_type arg_name arg_desc
    local mand_arg_pattern="<([^>]*)>"
    local  opt_arg_pattern="\[([^]]*)\]"

    arg_type=''
    if [[ "${input}" =~ ${mand_arg_pattern}* ]]; then
         arg_type=mandatory
    elif [[ "${input}" =~ ${opt_arg_pattern}* ]]; then
         arg_type=optional
    fi

    if [ "${arg_type}" ]; then
        arg_name="${BASH_REMATCH[1]}"
        arg_desc="$(str_trim "${input:${#BASH_REMATCH[0]}}")"

        _doc_flag_pack "${arg_name}" "${arg_type}" "$(str_escape "${arg_desc}")"
    fi
}

##
## @func doc_command
## @desc Formats a command's doc-block for display
## @arg <command>
## @out The formatted doc-block
##
function doc_command() {
    local command="${@}"

    module_include command
    local file=$( command_path_lookup "${@}" )
    local in_header=false line tag value
    local -a args flags exits descs authors see_alsos outputs 
    local arg flag desc author see_also output 
    local doc tmp

    if [ ! "${file}" ]; then
        return
    fi

    while read line; do
        line="$(str_trim "${line}")"
        if [[ "${line}" == ${__doc_leader__}*@* ]]; then
            in_header=true
                  tag="${line#*@}"; tag="${tag%%[[:space:]]*}"
                value="${line#*${tag}}"

            case ${tag} in
            desc|description)
                descs+=( "$(str_escape "${value}")" )
                ;;

            authors)
                authors+=( "$(str_escape "${value}")" )
                ;;

            arg|argument)
                args+=( "$(_doc_parse_arg "$(str_trim "${value}")" )"  )
                ;;

            flag)
                flags+=( "$(_doc_parse_flag "$(str_trim "${value}")" )" )
                ;;

            see|see-also)
                see_alsos+=( "$(str_escape "${value}")" )
                ;;

            out|outputs)
                outputs+=( "$(str_escape "${value}")" )
                ;;

            exit|exit-code)
                tmp="$(str_trim "${value}")"
                set ${tmp}
                exit_code=${1}
                shift
                exit_reason="$( str_escape "${*}" )"
                exits+=( "${exit_code}:${exit_reason}" )
                ;;
            esac
        elif ${in_header}; then
            break
        fi
    done < ${file}

    doc=''
    # section: command
    doc+="$(_doc_section command)"
    doc+="$(_doc_indent 1)${BLIB_COMMAND} ${command}"
    doc+="\n"

    # section: file
    doc+="$(_doc_section file)"
    doc+="$(_doc_indent 1)${file}"
    doc+="\n"

    # section: author
    if [ "${authors}" ]; then
        doc+="$(_doc_section author)"
        doc+="$(_doc_indent 1)${authors[@]}"
        doc+="\n"
    fi

    # section: description
    if [ "${descs}" ]; then
        doc+="$(_doc_section description)"
        for desc in "${descs[@]}"; do
            doc+="$(_doc_indent 1)${desc}\n"
        done
        doc+="\n"
    fi

    # section: flags
    if [ "${flags}" ]; then
        doc+="$(_doc_section flags)"
        for flag in "${flags[@]}"; do
            doc+="$(_doc_full_flag_description tool "${flag}")\n"
        done
        doc+="\n"
    fi

    # section: args
    if [ "${args}" ]; then
        doc+="$(_doc_section args)"
        for arg in "${args[@]}"; do
            doc+="$(_doc_full_arg_description tool "${arg}")\n"
        done
        doc+="\n"
    fi

    # section: output
    if [ "${outputs}" ]; then
        doc+="$(_doc_section output)"
        for output in ${outputs[@]}; do
            doc+="$(_doc_indent 1)${output}\n"
        done
        doc+="\n"
    fi

    # section: exits
    if [ "${outputs}" ]; then
        doc+="$(_doc_section "exit codes")"
        for e in ${exits[@]}; do
            set ${e/:/ }
            exit_code=${1}
            shift
            exit_reason="${*}"
            doc+="$(printf "%s%4s - %s" "$(_doc_indent 1)" "${exit_code}" "${exit_reason}")\n"
        done
        doc+="\n"
    fi

    doc="$(str_unescape "${doc}")"
    [ "${PAGER}" ] && \
        echo -e "${doc}" | ${PAGER} || \
        echo -e "${doc}"
}

##
## @func doc_module
## @desc Formats a module's doc-block for display
## @flag <module=name> The module's name
## @flag [function=name] Ask for just one function
## @out The formatted doc-block
##
function doc_module() {
    local the_module the_function guessed_module
    local functions func
    local doc str ptr tag value line
    local in_module=false in_func=false need_separator
    local opts=$( getopt -o '' --long "module:,function:" -n "${FUNCNAME}" -- "$@" )

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --module)
            the_module="${2}"
            shift 2
            ;;

        --function)
            the_function="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    #
    # Trick: if we were handed a module-name xxx, but the
    #        module is actually aaa/bbb/xxx.sh, fix it internally.
    #        
    if ! module_lookup ${the_module} >/dev/null; then
        if guessed_module=$( module_lookup_guess ${the_module}); then
            the_module=${guessed_module}
        fi
    fi

    functions="$( module_functions ${the_module} )"
    eval "local module_name=\"${the_module}\""
    eval "local module_file=\"\$( module_lookup ${the_module} )\""
    if [ ! "${module_file}" ] || [ ! -r ${module_file} ]; then
        return
    fi

    #
    # Gather the information from the doc-blocks in the file
    #
    while read line; do
        line="$(str_trim "${line}")"    # discard leading and trailing spaces

        if [[ ! "${line}" == ${__doc_leader__}*@* ]]; then
            if ${in_module}; then
                in_module=false
            elif ${in_func}; then
                in_func=false
            fi
            continue
        fi

          tag="${line#*@}"; tag="${tag%%[[:space:]]*}"
        value="$(str_escape "$(str_trim "${line#*${tag}}")")"

        case "${tag}" in
        module)
            in_module=true
            ;;

        function|func)
            in_func=true
            eval "local curr_func=\"${value}\""
            ;;

        version|author|brief|summary|desc|description|stdout|out|returns|ret|syntax)
            case "${tag}" in
            brief)  tag="summary"       ;;
            desc)   tag="description"   ;;
            ret)    tag="returns"       ;;
            out)    tag="stdout"        ;;
            esac

            if ${in_module}; then
                eval "local module_${tag}+=\"${value}\n\""
            elif ${in_func}; then
                if [ ${tag} = "description" ]; then
                    eval "local func_${curr_func}_${tag}+=\"${value}\n\""
                else
                    eval "local func_${curr_func}_${tag}=\"${value}\""
                fi
            fi
            ;;

        flag)
            if ${in_func}; then
                eval "local func_${curr_func}_flags=( \${func_${curr_func}_flags[@]} \"$(_doc_parse_flag "$(str_unescape "${value}")" )\" )"
            fi
            ;;

        arg)
            if ${in_func}; then
                eval "local func_${curr_func}_args=( \${func_${curr_func}_args[@]} \"$(_doc_parse_arg "$(str_unescape "${value}")")\" )"
            fi
            ;;

        esac

    done < ${module_file}

    # show the module info
    for attr in name file version author summary description; do
        eval "ptr=module_${attr}"
        if [ "${!ptr}" ]; then
            if [ "${attr}" = "name" ]; then
                doc+="$(_doc_section "module name")"
            else
                doc+="$(_doc_section "${attr}")"
            fi
            if [ "${ptr}" = "module_description" ]; then
                str="${!ptr}"
                while [ "${str}" ]; do
                    doc+="$(_doc_indent 1)${str%%\\n*}\n"
                    str="${str#*\\n}"
                done
            else
                doc+="$(_doc_indent 1)${!ptr}\n"
            fi
        fi
    done

    # show the functions info
    if [ "${functions}" ]; then
        doc+="\n$(_doc_section functions)"
        for func in ${functions}; do
            if [ "${the_function}" ] && [ ${the_function} != ${func} ]; then
                continue
            fi

            # Show the function name
            doc+="\n$(_doc_indent 1)$(str_color --bold white "${func}")"

            # Show the (optional) flags
            ptr=func_${func}_flags'[*]'
            if [ "${!ptr}" ]; then
                local _flags="${!ptr}"
                local _flag

                for _flag in ${_flags}; do
                    doc+=" $( _doc_inline_flag_description "${_flag}" )"
                done
            fi

            # Show the (optional) arguments
            ptr=func_${func}_args'[*]'
            if [ "${!ptr}" ]; then
                local _args="${!ptr}"
                local _arg

                for _arg in ${_args}; do
                    doc+=" $( _doc_inline_arg_description "${_arg}" )"
                done
            fi
            doc+='\n'

            need_separator=false
            # Describe the flags
            ptr=func_${func}_flags'[*]'
            if [ "${!ptr}" ]; then
                local _flags="${!ptr}"
                local _flag

                for _flag in ${_flags}; do
                    doc+="$( _doc_full_flag_description function "${_flag}" )"
                done
                need_separator=true
            fi

            # Describe the arguments
            ptr=func_${func}_args'[*]'
            if [ "${!ptr}" ]; then
                local _args="${!ptr}"
                local _arg

                for _arg in ${_args}; do
                    doc+="$( _doc_full_arg_description function "${_arg}" )"
                done
                need_separator=true
            fi

            # Show the (optional) output to stdout
            ptr="func_${func}_stdout"
            if [ "${!ptr}" ]; then
                doc+="$(_doc_indent 2)$(str_color --bold white out)  "${!ptr}"\n"
                need_separator=true
            fi

            # Show the (optional) return value
            ptr=func_${func}_returns
            if [ "${!ptr}" ]; then
                doc+="$(_doc_indent 2)$(str_color --bold white ret)  "${!ptr}"\n"
                need_separator=true
            fi

            # Show the (optional) summary
            ptr="func_${func}_summary"
            if [ "${!ptr}" ]; then
                doc+="$(_doc_indent 2)${!ptr}\n"
                need_separator=true
            fi

            # Show the (optional) description
            ptr="func_${func}_description"
            if [ "${!ptr}" ]; then
                if ${need_separator}; then
                    doc+="\n"
                fi
                str="${!ptr}"
                while [ "${str}" ]; do
                    doc+="$(_doc_indent 2)${str%%\\n*}\n"
                    str="${str#*\\n}"
                done
            fi
        done
    fi
    doc+="\n"

    doc="$(str_unescape "${doc}")"
    [ "${PAGER}" ] && \
        echo -e "${doc}" | ${PAGER} || \
        echo -e "${doc}"
}

function doc_init() {
        _doc_flag_separator=$'\x07'
        _doc_mandatory_deco=""
         _doc_optional_deco="[]"
             __doc_indent__="   "
             __doc_leader__="##"
}
