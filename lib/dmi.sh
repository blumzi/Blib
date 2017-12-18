module_include error str user

function dmi_get() {
    if ! user_is_root; then
        error_warning "Must be \"root\"."
        return 1
    fi

    local section item index file generate_dmi
    local opts=$( getopt -o '' --long section:,item:,index:,file:,compacted-section:,compacted-item: -n "${FUNCTION}" -- "$@" )

    eval set -- "${opts}"
    while true; do
        case "${1}" in
        --file)
            file="${2}"
            shift 2
            ;;

        --section)
            section="${2}"
            shift 2
            ;;
        --compacted-section)
            section="$( str_uncompact "${2}" )"
            shift 2
            ;;
        
        --item)
            item="${2}"
            shift 2
            ;;

        --compacted-item)
            item="$( str_uncompact "${2}" )"
            shift 2
            ;;

        --index)
            index="${2}"
            shift 2
            ;;

        --)
            shift 1
            break
            ;;
        esac
    done

    if [ "${file}" ]; then
        generate_dmi="cat ${file}"
    else
        generate_dmi="dmidecode"
    fi

    if [ ! "${section}" ]; then
        ${generate_dmi}
        return
    fi

    ${generate_dmi} | awk -F: -v section="${section}" -v item="${item}" -v index="${index}" '
        function trim(s) {
            sub("^[[:space:]]*", "", s)
            sub("[[:space:]]*$", "", s)
            return s
        }

        /^Handle/ {
            if (multi["name"]) {
                if (! item)
                    printf "%-30s %s\n", multi["name"] ":", multi["val"]
                else if (item == multi["name"])
                    print multi["val"]
                    multi["name"] = multi["val"] = ""
            }
            start = NR
            curr_section = ""
            next
        }
        start && NR == start + 1 {
            curr_section = trim($0)
            next
        }

        section == curr_section {
            tag   = trim($1)
            value = trim($2)

            if (NF == 2)
                if (multi["name"]) {
                    if (! item)
                        printf "%-30s %s\n", multi["name"] ":", multi["val"]
                    else if (item == multi["name"])
                        print multi["val"]
                    multi["name"] = multi["val"] = ""
                }

            if (NF == 2 && !value) {
                multi["name"] = tag
                multi["val"] = ""
                # print ">>> tag: [" tag "], name: ["  multi["name"] "]"
                next
            }

            if (NF == 1) {
                if (multi["val"])
                    multi["val"] = multi["val"] ", " trim($0)
                else
                    multi["val"] = trim($0)
                # print ">>> val: ["  multi["val"] "]"
                next
            }

            if (! item && tag ) {
                printf "%-30s %s\n", tag ":", value
            } else {
                if (item == tag)
                    print value
            }
            next
        }
    '
}
