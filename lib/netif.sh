#!/bin/bash

module_include ip oem log error const misc platform

function netif_info() {
	declare ifc=${1}

	ifconfig ${ifc}
}

function netif_mac() {
	declare ifc=${1}

	netif_info ${ifc} | awk 'NR == 1 && $4 == "HWaddr" { print $5 }'
}

function netif_broadcast() {
	declare ifc=${1}

	netif_info ${ifc} | awk ' $1 == "inet" { split($3, arr, ":"); print arr[2] } '
}

function netif_mask() {
	declare ifc=${1}

	netif_info ${ifc} | awk ' $1 == "inet" { split($4, arr, ":"); print arr[2] } '
}

function netif_addr() {
	declare ifc=${1}

	netif_info ${ifc} | awk ' $1 == "inet" { split($2, arr, ":"); print arr[2] } '
}

function netif_is_up() {
	declare ifc="${1}"

	ifconfig ${ifc} | grep -qw UP
}

function netif_exists() {
	declare ifc="${1}"

	egrep -qE "^[[:space:]]*${ifc}:" /proc/net/dev 
}

function netif_oem_map_ifc() {
	declare ifc="${1}"
	declare vendor=$( oem_vendor )
	declare i
	declare -a circuits physical_nics

	case "${vendor}" in
	Crossbeam)
		return 1
		;;
	*)
		echo ${ifc}
		;;
	esac
}

function netif_set_affinity() {
	declare ifc="${1}"
	declare cpu="${2}"
	declare -a info
	declare irq x current i hex tries read_back affinity_message hex_width

	ifc=$( netif_oem_map_ifc "${ifc}" )

	if ! netif_is_up ${ifc}; then
		ifconfig ${ifc} up || return 1
	fi

	info=( $( grep -w "${ifc}" /proc/interrupts ) )
	if [ "${#info[*]}" -eq 0 ]; then
		return 1
	fi

	#
	# If the NIC's interrupt is handled by a XT-PIC (XT style Programable Interrupt Controller), don't
	#  even try to set the affinity because the PIC doesn't allow such things
	#
	# NOTE:
	#   This also happens on nachines that originally use an IO-APIC, but we disable it with
	#    a noapic kernel parameter, such as in the AspenHill case.  The Aspen Hill box has only
	#    one CPU to start with, so there's no need to set any affinity.
	#
	for (( i = 0; i < ${#info[*]}; i++ )); do
		if [[ ${info[${i}]} == *PIC* ]]; then
			if [ ${info[${i}]} = XT-PIC ]; then
				return 0
			fi
		fi
	done

	irq=$( echo ${info[0]%:*} )				# get rid of leading spaces as well

	if [ ! -e /proc/irq/${irq}/smp_affinity ]; then
		return 1
	fi

	hex_width=$(< /proc/irq/${irq}/smp_affinity)
	hex_width=${#hex_width}
	if ! grep -wq "^${irq}" ${const_saved_affinities}; then
		x=$(< /proc/irq/${irq}/smp_affinity)
		x=$(( 16#${x} ))
		printf "%-5d  %-3d\n" "${irq}" "${x}" >> ${const_saved_affinities}
	fi

	affinity_message="set affinity of irq \"${irq}\" to cpu \"${cpu}\" for interface \"${ifc}\"."
	hex="$( printf "%08x" $(( 1 << ${cpu} )) )"
	hex=${hex: -${hex_width}:${hex_width}}
	log_msg "Attempting to ${affinity_message}"
	echo ${hex} > /proc/irq/${irq}/smp_affinity	# set the affinity
	for (( tries = 50; tries; tries-- )); do
		read_back=$(< /proc/irq/${irq}/smp_affinity )
		if [ "${read_back}" = "${hex}" ]; then
			break
		fi
		usleep 100000
	done

	if [ ${tries} -eq 0 ]; then
		error_fatal "Failed to ${affinity_message}"
	fi
	log_msg "Succeeded to ${affinity_message}"
	return 0
}

function netif_get_affinity() {
	declare dev irq aff cpu mask cpus hex=false

	if [ "${1}" = "--hex" ]; then
		hex=true
		shift 1
	fi
	dev="${1}"

	irq=$( grep -w ${dev} /proc/interrupts | cut -d: -f1 )
	irq=$( echo ${irq} )			# get rid of leading spaces
	if [ ! "${irq}" ]; then
		return
	fi

	aff=/proc/irq/${irq}/smp_affinity
	if [ -r ${aff} ]; then			# will not exist on uniprocessors
		if ${hex}; then
			echo $(< ${aff})
			return 0
		fi

		mask=0x$(< ${aff})
		for (( cpu = 0; cpu < 32 ; cpu++ )); do
			if [ $(( mask & ( 1 << cpu ) )) -ne 0 ]; then
				if [ "${cpus}" ]; then
					cpus="${cpus} ${cpu}"
				else
					cpus=${cpu}
				fi
			fi
		done
		echo ${cpus}
		return 0
	fi

	return 1
}

function netif_set_module_options() {
	declare -a ethers drivers
	declare ether driver

	ethers=( $(
		while read dev dummy; do
			if [[ "${dev}" == eth[0-9]:* ]]; then
				echo ${dev%:*}
			fi
		done < /proc/net/dev
	) )

	for ether in ${ethers}; do
		driver="$( ethtool -i ${ether} | grep driver: )"
		driver=${driver#driver: }

		if [ "${driver}" = e1000 ]; then

			ethtool -K ${ether} rx off  >/dev/null 2>&1 || \
						log_msg --priority WARNING  "${FUNCNAME}: Cannot turn RX checksums off for interface ${ether}"

			ethtool -G ${ether} rx 4098 >/dev/null 2>&1 || \
						log_msg --priority WARNING "${FUNCNAME}: Cannot set 4098 RX descriptors for interface ${ether}"
		fi
	done
}

function netif_last_alias() {
	declare     device="${1}"

	# In case nic is down..
	if ! ifconfig ${device} up > /dev/null 2>&1; then
		log_msg --priority ERROR "Cannot UP the ${device}"
	fi

	declare -a aliases=( $( ifconfig | awk '/^'${device}'/{print $1}' ) )
	declare last_alias=${aliases[${#aliases[*]} - 1]}

	echo "${last_alias}"
}

function netif_common_network() {
	declare   first_ip="${1}"
	declare  second_ip="${2}"
	declare segment_ip="${3}"

	declare  first_network="$( ip_netpart "${first_ip}"  "${segment_ip}" )"
	declare second_network="$( ip_netpart "${second_ip}" "${segment_ip}" )"

	[ "${first_network}" = "${second_network}" ] && return 0 || return 1
}
