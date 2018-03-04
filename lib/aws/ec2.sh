##
## @module  ec2
## @author  Arie Blumenzweig
## @desc    AWS EC2 related functions.  Uses jq(1) to parse JSON.
##

# Cache of the ec2 instances data
_ec2_instances_data=''

function _ec2_fetch_instance_data() {
    if [ ! "${_ec2_instances_data}" ]; then
        _ec2_instances_data="$(aws ec2 describe-instances)"
    fi
    echo "${_ec2_instances_data}"
}

function ec2_host_to_instance() {
    local opts=$( getopt -o '' --long "reload" -n "${FUNCNAME}" -- "$@" )
    local hostname="${1}"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --reload)
            _ec2_instances_data=''
            shift 1
            ;;

        --)
            shift 1
            break
        esac
    done


    _ec2_fetch_instance_data |  \
        jq --raw-output  '.Reservations[].Instances[] | select(.Tags[0].Value == "'${hostname}'") | .InstanceId'
}

function ec2_instance_to_host() {
    local opts=$( getopt -o '' --long "reload" -n "${FUNCNAME}" -- "$@" )
    local instance="${1}"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --reload)
            _ec2_instances_data=''
            shift 1
            ;;

        --)
            shift 1
            break
        esac
    done

    _ec2_fetch_instance_data | \
        jq --raw-output  '.Reservations[].Instances[] | select(.InstanceId == "'${instance}'") | .Tags[0].Value'
}

function ec2_get_attribute() {
    local opts=$( getopt -o '' --long "reload,hostname:,instance-id:,attribute:" -n "${FUNCNAME}" -- "$@" )
    local hostname instance_id attribute

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --reload)
            _ec2_instances_data=''
            shift 1
            ;;

        --instance-id)
            instance_id="${2}"
            shift 2
            ;;

        --hostname)
            hostname="${2}"
            shift 2
            ;;

        --attribute)
            attribute="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    if [ ! "${attribute}" ]; then
        return
    fi

    if [ ! "${instance_id}" ]; then
        if [ "${hostname}" ]; then
            instance_id="$( ec2_host_to_instance "${hostname}")"
        else
            return
        fi
    fi

    [ "${instance_id}" ] || return 1

    _ec2_fetch_instance_data | \
        jq --raw-output  '.Reservations[].Instances[] | select(.InstanceId == "'${instance_id}'") | '"${attribute}"
}

function ec2_instance_status() {
    local opts=$( getopt -o '' --long "reload,hostname:,instance-id:" -n "${FUNCNAME}" -- "$@" )
    local instance_id hostname

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --reload)
            _ec2_instances_data=''
            shift 1
            ;;

        --instance-id)
            instance_id="${2}"
            shift 2
            ;;

        --hostname)
            hostname="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    if [ ! "${instance_id}" ]; then
        if [ "${hostname}" ]; then
            instance_id="$( ec2_host_to_instance "${hostname}" )"
        else
            return
        fi
    fi

    [ "${instance_id}" ] || return 1

    ec2_get_attribute --instance-id=${instance_id} .State.Name
}


function ec2_get_public_hostname() {
    local opts=$( getopt -o '' --long "reload" -n "${FUNCNAME}" -- "$@" )

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --reload)
            _ec2_instances_data=''
            shift 1
            ;;

        --)
            shift 1
            break
        esac
    done

    _ec2_fetch_instance_data | \
        jq --raw-output '.Reservations[].Instances[] | select(.PrivateDnsName | startswith("'$(hostname)'")) | select(.Tags[].Key == "Name") .Tags[].Value'
}
