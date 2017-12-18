module_include const str

function ip_is_quad() {
    local addr q maxquad=255
    local -a quad

    addr="${1}"
    IFS=.
    quad=( ${addr} )
    IFS=${const_default_IFS}
    [ ${#quad[*]} -ne 4 ] && return 1
    [[ "${addr}" == *[^[:digit:].]* ]] && return 1
    for q in ${quad[*]}; do
        if [ ${q} -gt ${maxquad} ]; then
            return 1
        fi
    done
    if [ "${quad[0]}.${quad[1]}.${quad[2]}.${quad[3]}" != "${addr}" ]; then
        return 1    # superfluous leading or trailing dots
    fi

    return 0
}

function ip_is_netmask_quad() {
    local mask="${1}" q
    local -a quad

    if [ "${mask}" = "255.255.255.255" ]; then  # special cases
        return 1
    fi

    IFS=.
    quad=( ${mask} )
    IFS=${const_default_IFS}
    [ ${#quad[*]} -ne 4 ] && return 1
    [[ "${mask}" == *[^[:digit:].]* ]] && return 1
    for q in ${quad[*]}; do
        [ ${q} -gt 255 ] && return 1
    done
    if [ "${quad[0]}.${quad[1]}.${quad[2]}.${quad[3]}" != "${mask}" ]; then
        return 1    # superfluous leading or trailing dots
    fi

    return 0
}

function ip_prefix_to_mask() {
        local prefix="${1}"
        local -a dec
        local shift_left ones bits

        ones=$(( ( 1 << prefix ) - 1 ))
        shift_left=$(( 32 - prefix ))
        bits=$(( ones << shift_left ))

        dec[0]=$(( ( bits >> 24 ) & 0xff ))
        dec[1]=$(( ( bits >> 16 ) & 0xff ))
        dec[2]=$(( ( bits >>  8 ) & 0xff ))
        dec[3]=$(( ( bits >>  0 ) & 0xff ))

        printf "%d.%d.%d.%d\n" ${dec[0]} ${dec[1]} ${dec[2]} ${dec[3]}
}

function ip_mask_to_prefix() {
    local mask="${1}"
    local val=$( ip_quad2hex "${mask}" )
    local prefix i

    for (( i = 31; i; i-- )); do
        if (( val & ( 1 << i ) )); then
            (( prefix++ ))
        else
            break
        fi
    done
    echo ${prefix}
}

function ip_quad2hex() {
    local quad="${1}"
    local -a quads
    local hex i

    quad="$( str_trim "${quad}" )"
    IFS=.
    quads=( ${quad} )
    IFS=${const_default_IFS}
    for (( i = 0; i < 4; i++ )); do
        hex=$(( hex | ( quads[i] << (8 * (3 - i)) ) ))
    done
    printf "0x%x\n" ${hex}
}

function ip_hex2quad() {
    local hex="${1}"
    local -a quads
    local i

    for (( i = 0; i < 4; i++ )); do
        quads[${i}]=$(( ( hex >> ( 8 * ( 3 - i ) ) ) & 0xff ))
    done
    printf "%d.%d.%d.%d\n" ${quads[0]} ${quads[1]} ${quads[2]} ${quads[3]}
}

function ip_netpart() {
    local addr="${1}"
    local mask="${2}"

    ip_hex2quad $(( $( ip_quad2hex "${addr}" ) & $( ip_quad2hex "${mask}" ) ))
}

function ip_hostpart() {
    local addr="${1}"
    local mask="${2}"

    ip_hex2quad $(( $( ip_quad2hex "${addr}" ) & ~$( ip_quad2hex "${mask}" ) ))
}

function ip_bcast() {
    local addr="${1}"
    local mask="${2}"
    local  net=$( ip_quad2hex "$( ip_netpart "${addr}" "${mask}" )" )
    local host=$( ip_quad2hex "$( ip_hostpart 255.255.255.255 "${mask}" )" )

    ip_hex2quad $(( net | host ))
}

function ip_range() {
    local addr="${1}"
    local mask="${2}"
    local  len="${3}"
    local  net=$( ip_quad2hex "$( ip_netpart "${addr}" "${mask}" )" )
    local host=$( ip_quad2hex "$( ip_hostpart "${addr}" "${mask}" )" )
    local  max=$( ip_quad2hex $( ip_hostpart 255.255.255.255 "${mask}" ) )
    local -a hosts

    if (( host > max )); then
        return
    fi

    for (( ; len; len-- )); do
        hosts[${#hosts[*]}]=$( ip_hex2quad "$(( net | host ))" )
        (( host++ ))
        if (( host > max )); then
            break
        fi
    done

    echo ${hosts[*]}
}
