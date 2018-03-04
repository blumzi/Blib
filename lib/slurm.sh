##
## @module slurm
## @desc Wrapper functions for the slurm sub-system
## @author Arie Blumenzweig <ablumenzweig@gsitechnology.com>
##

source /etc/profile.d/blib.sh

module_include list

_slurm_config_file="/etc/slurm/slurm.conf"

##
## @func slurm_is_compute_node
## @desc Checks if the given node name is a slurm compute node
## @arg  hostname
## @ret  true/false
##
function slurm_is_compute_node() {
    local node="${1}"
    local nodenames junk

    if [ ! -r "${_slurm_config_file}" ]; then
        return 1
    fi

    while read nodenames junk; do
        nodenames=${nodenames#NodeName=}
        nodenames=( $( scontrol show hostname ${nodenames} ) )
        if list_member "${node}" "${nodenames[*]}"; then
            return 0
        fi
    done < <( grep '^NodeName=' ${_slurm_config_file})
    return 1
}

##
## @func slurm_is_control_node
## @desc Checks if the given node name is a slurm control node
## @arg  hostname
## @ret  true/false
##
function slurm_is_control_node() {
    local node="${1}"
    local controll_machine junk

    read controll_machine junk < <( grep '^ControlMachine=' ${_slurm_config_file} )
    [ "${controll_machine}" = "${node}" ]
}

##
## @func slurm_is_db_node
## @desc Checks if the given node name is a slurm data-base node
## @arg  hostname
## @ret  true/false
##
function slurm_is_db_node() {
    local node="${1}"
    local db_machine junk

    read db_machine junk < <( grep '^AccountingStorageHost=' ${_slurm_config_file} )
    [ "${db_machine}" = "${node}" ]
}
