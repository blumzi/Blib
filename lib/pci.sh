#!/bin/bash

module_include error user

#
#    Function:  pci_loc
#      Syntax:  pci_loc <eth-index>
# Description:  Gets the PCI location of the Ethernet at <eth-index>
#     Returns:  Nothing relevant
#     Outputs:  The PCI location of the Ethernet at <eth-index>
#
function pci_loc() {
    declare eth=${1}
    declare label value

    if ! user_is_root; then
        error_warning "${FUNCNAME}: Must be root."
        return 1
    fi

    #
    # older versions of ethtool(1) print the bus information as
    #  bus:dev.fun while newer ones as xxxx:bus:dev.fun
    #
    ethtool -i ${eth} 2>/dev/null | while read label value; do
        if [ "${label}" = "bus-info:" ]; then
            echo ${value#0000:}
            return 0
        fi
    done
    return 1
}

#
#    Function:  pci_id
#      Syntax:  pci_id <pci-location>
# Description:  Gets the PCI id for the device at <pci-location>
#     Returns:  Nothing relevant
#     Outputs:  The PCI id in the format vid:did
#
function pci_id() {
    declare loc=${1}
    declare -a info

    if [ ! "${loc}" ]; then
        return
    fi
    info=( $( lspci -n -s ${loc} ) )
    [ "${info[1]}" = Class ] && echo ${info[3]} || echo ${info[2]}
}

#
#    Function:  pci_sid
#      Syntax:  pci_sid <pci-location>
# Description:  Gets the PCI subsystem id for the device at <pci-location>
#     Returns:  Nothing relevant
#     Outputs:  The PCI subsystem id in the format svid:sdid
#
function pci_sid() {
    declare loc=${1}
    declare label value

    if [ ! "${loc}" ]; then
        return
    fi
    lspci -nv -s ${loc} | while read label value; do
        if [ "${label}" = "Subsystem:" ]; then
            echo "${value}"
            return 0
        fi
    done
    return 1
}

#
#    Function:  pci_description
#      Syntax:  description <pci-location>
# Description:  Gets the description for the device at <pci-location>
#     Returns:  Nothing relevant
#     Outputs:  The PCI device description
#
function pci_desc() {
    declare loc="${1}"
    declare -a info

    if [ ! "${loc}" ]; then
        return
    fi
    info=$( lspci -s ${loc} )
    echo ${info#*:[[:space:]]}
}

#
#    Function:  pci_type
#      Syntax:  pci_type <pci-location>
# Description:  Gets the PCI device type for the device at <pci-location>
#     Returns:  Nothing relevant
#     Outputs:  The PCI device type
#
function pci_type() {
    declare loc="${1}"
    declare -a info

    if [ ! "${loc}" ]; then
        return
    fi
    info=$( lspci -s ${loc} )
    info=${info#*[[:space:]]}
    echo ${info%%:*}
}
