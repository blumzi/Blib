module_include misc

##
## @module  http
## @desc
## @desc    Performs http actions, using wget(1).
## @desc
## @author  Arie Blumenzweig <theblumz@gmail.com>
##

##
## @func http_get
## @flag [timeout=seconds] Total timeout
## @arg  url
## @desc Performs a wget for the specified URL.
## @out  The resulting contents.
##
function http_get() {
    declare url args timeout=5
    declare opts=$( getopt -o 't:' --long timeout: -n "${prog}" -- "$@" )

    eval set -- "${opts}"

    while true; do
        case "${1}" in
        -t|--timeout)
            timeout=${2}
            shift 2
            ;;
        
        --)
            shift
            break
            ;;
        esac
    done

    url="${1}"
    if [[ "${url}" == https:* ]]; then
        args=$( _http_make_client_auth_args )
        if [ $? -eq 0 ]; then
            args="--no-check-certificate ${args}"
        else
            declare certfile=${BLIB_ETC}/gwcert.crt args

            args="${args} --no-check-certificate"
            if [ -r ${certfile} ]; then
                args="${args} --certificate=${certfile}"
            fi
        fi
    fi

    wget ${args} --timeout=${timeout} --tries=1 -q -O - "${url}"
}

function http_response_code() {
    declare file=${1}
    declare -a info

    info=( $( grep "HTTP request sent, awaiting response... " ${file} ) )

    echo ${info[5]}
}

function http_response_desc() {
    declare file=${1}
    declare desc

    desc=$( grep ERROR ${file} )
    desc="${desc#*(}"
    desc="${desc%)*}"

    echo "${desc}"
}

function http_post() {
    declare opts=$( getopt -o 'h:r:t:' --long "header:,no-keepalive,retries:,timeout:" -n "${prog}" -- "$@" )
    declare code status proto extra_args
    declare url data tmp timeout=10 retries

    eval set -- "${opts}"

    while true; do
        case "${1}" in
        -h|--header)
            headers+=( "--header" "${2}" )
            shift 2
            ;;

        --no-keepalive)
            extra_args="--no-http-keep-alive"
            shift 1
            ;;

        -r|--retries)
            retries="--tries=${2}"
            shift 2
            ;;

        -t|--timeout)
            timeout=${2}
            shift 2
            ;;
        
        --)
            shift
            break
            ;;
        esac
    done

     url="${1}"
    data="${2}"
     tmp="${3}"

    extra_args+=" -v"
    proto=${url%%:*}
    if [ "${proto}" = https ]; then
        extra_args+=" --no-check-certificate $( _http_make_client_auth_args )"
    fi

    wget --timeout=${timeout} ${retries} "${headers[@]}" ${extra_args} -O - --post-data="${data}" "${url}" 2>${tmp}
    status=$?

    return ${status}
}

# vim: set ts=4 sw=4 expandtabs
