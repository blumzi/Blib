module_include str

##
## @func    _doc_flag_pack
## @desc    Packs the arguments tightly, using a non-printable
## @desc     separator.  The whole string can then be passed
## @desc     as a single argument to other functions.
##
function _doc_flag_pack() {
    local str arg

    for arg in "${@}"; do
        str+="${arg}${_doc_flag_separator}"
    done
    echo "${str%${_doc_flag_separator}}"
}

##
## @func    _doc_parse_flag
## @desc    Parses a @flag line in a doc-block
## @out     The flag's name, type, value and description, packed.
##
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

##
## @func    _doc_parse_arg
## @desc    Parses a @arg line in a doc-block
## @out     The arg's name, type, value and description, packed.
##
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
## @desc Parses and formats a command's doc-block for display
## @arg <command>
## @out The formatted doc-block
##
function doc_command() {
    local format=text
    local opts=$( getopt -o '' --long "format:,man" -n "${FUNCNAME}" -- "$@" )
    local command

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --format)
            format="${2}"
            shift 2
            ;;

        -*)
            shift 1
            ;;

        *)
            break
            ;;
        esac
    done

    command="${@}"

    module_include command
    local file=$( command_path_lookup "${@}" )
    local in_header=false line tag value
    local -a args flags exits descs authors see_alsos outputs 
    local arg flag see_also output 
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
                if [ ! "${value}" ]; then
                    value="${const_escaped_newline}"
                fi
                descs+=( "$(str_escape "${value}")" )
                ;;

            author)
                authors+=( "$(str_escape "$(str_trim "${value}")" )" )
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
            if [[ "${line}" == ${_doc_leader__}* ]]; then
                continue
            else
                break
            fi
        fi
    done < ${file}

    module_include doc/doc${format}

     doc=''
    doc+="$( eval ${doc_render_command}     "${command}"    )"
    doc+="$( eval ${doc_render_file}        "${file}"       )"
    doc+="$( eval ${doc_render_authors}     "${authors[@]}" )"
    doc+="$( eval ${doc_render_description} "${descs[@]}"   )"
    doc+="$( eval ${doc_render_flags}       "${flags[@]}"   )"
    doc+="$( eval ${doc_render_args}        "${args[@]}"    )"
    doc+="$( eval ${doc_render_outputs}     "${outputs[@]}" )"
    doc+="$( eval ${doc_render_exits}       "${exits[@]}"   )"

    doc="$(str_unescape "${doc}")"
    [ "${PAGER}" ] && \
        echo -e "${doc}" | ${PAGER} || \
        echo -e "${doc}"
}

##
## @func doc_module
## @desc Parses and formats a module's doc-block for display
## @flag <module=name> The module's name
## @flag [function=name] Ask for just one function
## @out The formatted doc-block
##
function doc_module() {
    local the_module the_function guessed_module
    local functions func
    local doc str ptr tag value line
    local in_module=false in_func=false need_separator
    local format=text
    local opts=$( getopt -o '' --long "format:,module:,function:" -n "${FUNCNAME}" -- "$@" )

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --format)
            format="${2}"
            shift 2
            ;;

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

    module_include doc/doctext

    # show the module info
    for attr in name file version author summary description; do
        eval "ptr=module_${attr}"
        if [ "${!ptr}" ]; then
            doc+="$( ${doc_render_module_section} "${attr}" "${!ptr}" )"
        fi
    done

    # show the functions info
    if [ "${functions}" ]; then
        doc+="$( ${doc_render_module_section} "functions" "" )"

        for func in ${functions}; do
            local function_name function_flags function_args function_desc

            if [ "${the_function}" ] && [ ${the_function} != ${func} ]; then
                continue
            fi

                   function_name=func
                  function_flags=func_${func}_flags'[*]'
                   function_args=func_${func}_args'[*]'
                 function_stdout=func_${func}_stdout
                function_returns=func_${func}_returns
                function_summary=func_${func}_summary
            function_description=func_${func}_description

            doc+="$( ${doc_render_module_function} \
                        "${!function_name}" \
                        "${!function_flags}" \
                        "${!function_args}" \
                        "${!function_stdout}" \
                        "${!function_returns}" \
                        "${!function_summary}" \
                        "${!function_description}" \
                    )"
        done
    fi

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
