module_include xml tmp

__xmlrpc_responder__=${BLIB_COMMAND}
__xmlrpc_port__=8087

function xmlrpc_fault() {
    local   code="${1}"
    local string="${2}"

    xml_version
    xml_element methodResponse $(
        xml_element fault $(
            xml_element value $(
                xml_element struct $(
                    xml_element member $(
                        xml_element name faultCode
                        xml_element value $( xml_element int "${code}" )
                    )
                    xml_element member $(
                        xml_element name faultString
                        xml_element value "${string}"
                    )
                )
            )
        )
    )
}

function xmlrpc_response() {
    local message="${1}"

    xml_version
    xml_element methodResponse $(
        xml_element params $(
            xml_element param $(
                xml_element value "${message}"
            )
        )
    )
}

function xmlrpc_dispatch() {
    local body="${1}"
    local rc params

    method="$( echo "${body}" | xml_get_from_pipe "//methodCall/methodName" )"
    if [[ "${method}" != ${__xmlrpc_responder__}.* ]]; then
        rc=1
        xmlrpc_fault ${rc} "Not a ${__xmlrpc_responder__} method"
        return ${rc}
    fi

    method=${method#${__xmlrpc_responder__}.}
    method=xmlrpc_method_${method}
    if ! typeset -f ${method} >/dev/null; then
        rc=2
        xmlrpc_fault ${rc} "Unknown ${BLIB_COMMAND} method"
        return ${rc}
    fi

    params="$( echo "${body}" | xml_get_from_pipe "//methodCall/params" )"
    ${method} "${params}"
}

function xmlrpc_method_RunCommands() {
    local body="${1}"
    local -a commands
    local command stdout output status

    commands=( $( echo "${body}" | xml_get_from_pipe "//params/param/value" ) )
    for command in ${commands[*]}; do
        command=$( str_decode "${command}" )
        stdout=$( ${command} | while read line; do
                        echo "${line}<br>"
                    done
        )
        status=$?
        if [ ${status} -ne 0 ]; then
            xmlrpc_fault ${status} Failed
            return ${status}
        else
            output="${output}${stdout}"
        fi
    done

    xmlrpc_response "$( xml_esc "${output}" )"
    return 0
}

function xmlrpc_run_commands() {
    local opts=$( getopt -o 's:c:p:' --long "server-addr:,command:,server-port:" -n "${prog}" -- "$@" )
    local server_addr server_port=${__xmlrpc_port__} command
    local -a commands

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        -p|--server-port)
            server_port="${2}"
            shift 2
            ;;

        -s|--server-addr)
            server_addr="${2}"
            shift 2
            ;;

        -c|--command)
            commands[${#commands[@]}]="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    args="--server-addr=${server_addr} --method=RunCommands --server-port=8087 --ssl"
    for command in "${commands[@]}"; do
        args="${args} --encoded-param=$( str_encode "${command}" )"
    done
    xmlrpc_call ${args}
}

function xmlrpc_call() {
    local opts=$( getopt -o 'm:s:p:e:' --long "server-addr:,server-port:,ssl,param:,encoded-param:,method:" -n "${prog}" -- "$@" )
    local server_addr server_port server_proto data url tmp rfile ssl=false
    local -a params

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        -m|--method)
            method="${2}"
            shift 2
            ;;

        -s|--server-addr)
            server_addr="${2}"
            shift 2
            ;;

        --server-port)
            server_port="${2}"
            shift 2
            ;;

        --ssl)
            ssl=true
            shift 1
            ;;

        -e|--encoded-param)
            encoded_params[${#encoded_params[@]}]="${2}"
            shift 2
            ;;

        -p|--param)
            params[${#params[@]}]="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    data="$(
        xml_version
        xml_element "methodCall" "$(
            xml_element "methodName" "${BLIB_COMMAND}.${method}"
            xml_element "params" "$(
                for param in "${params[@]}"; do
                    xml_element "param" "$(
                        xml_element "value" "${param}"
                    )"
                done
                for param in "${encoded_params[@]}"; do
                    xml_element "param" "$(
                        xml_element "value" "$(
                            xml_element "base64" "${param}"
                        )"
                    )"
                done
            )"
        )"
    )"

    ${ssl} && server_proto=https || server_proto=http

      url=${server_proto}://${server_addr}:${server_port}/
      tmp=$( tmp_mkfile ${FUNCNAME} )
    rfile=$( tmp_mkfile ${FUNCNAME}.code )

    http_post --header='X-Svtsrv: valid' --header='Connection: close' --timeout=60 --no-keepalive ${url} "${data}" ${rfile} > ${tmp}
    if [ $? -ne 0 ]; then
        local code=$(http_response_code ${rfile})
        local desc=$(http_response_desc ${rfile})

        log_msg --priority WARNING "Cannot connect to ${server_addr}:${server_port} [HTTP response ${code} (${desc})]"
    else
        xml_format ${tmp}
        rm -f ${tmp} ${rfile}
    fi
}
