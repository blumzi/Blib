module_include error const

function calc_percent() {
    local percent="${1}"
    local    from="${2}"

    echo $(( ${from} * ${percent} / 100 ))
}

function calc_human2bytes() {
    local    arg="${1}"
    local out_of="${2}"
    local num mod out_of_bytes

    num=${arg%[kKmMgG%]}
    mod=${arg:${#num}:1}

    if [[ "${num}" != ${num//[^0-9]/} ]]; then
        error_fatal "Expecting natural number, got \"${num}\"."
    fi

    case "${mod}" in
    "")
        bytes=${num}
        ;;

    m | M)
        bytes=$(( ${num} * ${const_mb} ))
        ;;
    
    k | K)
        bytes=$(( ${num} * ${const_kb} ))
        ;;
    
    g | G)
        bytes=$(( ${num} * ${const_gb} ))
        ;;
    
    % | p | P)
        if [ ! "${out_of}" ]; then
            error_fatal "Expecting amount for %"
        fi
        out_of_bytes=$( calc_human2bytes ${out_of} )
        bytes=$( calc_percent ${num} ${out_of_bytes} )
        ;;
    *)
        error_fatal "Invalid modifier \"${mod}\" in \"${arg}\"."
        ;;
    esac
    echo ${bytes}
}

function calc_bytes2human() {
    local    bytes="${1}"
    local floor_to="${2}"

    case "${floor_to}" in
    g|G)
        bytes=$(( ${bytes} / ${const_gb} ))
        ;;
    m|M)
        bytes=$(( ${bytes} / ${const_mb} ))
        ;;
    k|K)
        bytes=$(( ${bytes} / ${const_kb} ))
        ;;
    esac

    if (( bytes % const_gb == 0 )); then
        echo "$(( bytes / const_gb ))g"
    elif (( bytes % const_mb == 0 )); then
        echo "$(( bytes / const_mb ))m"
    elif (( bytes % const_kb  == 0 )); then
        echo "$(( bytes / const_kb ))k"
    else
        echo ${bytes}
    fi
}

function calc_seconds2date() {
    local secs utc

    if [ "${1}" = "-u" ]; then
        utc="-u"
        secs="${2}"
    else
        secs="${1}"
    fi

    date ${utc} -d "1970-01-01 UTC ${secs} seconds"
}
