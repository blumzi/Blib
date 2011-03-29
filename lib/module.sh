#!/bin/bash

if ! typeset -F __module_marker__ > /dev/null; then

    function __module_marker__() {
        :
    }

    #
    # Lookup a module along the BLIB_PATH.
    # NOTE: Module names can resemble directories, e.g. storage/volume or platform/user
    #

    function module_lookup() {
        local module="${1}"
        local dir modfile

        for dir in ${BLIB_PATH//:/ }; do
            modfile=${dir}/lib/${module}.sh
            if [ -r ${modfile} ]; then
                echo ${modfile}
                return 0
            fi
        done
        return 1
    }

    function module_lookup_guess() {
        local module="${1}"
        local dir modfile

        for dir in ${BLIB_PATH//:/ }; do
            modfile=$(find ${dir}/lib -name ${module}.sh)
            if [ "${modfile}" ] && [ -r ${modfile} ]; then
                modfile=${modfile#${dir}/lib/}
                modfile=${modfile%.sh}
                echo ${modfile}
                return 0
            fi
        done
        return 1
    }

    function module_include() {
        local module modules modfile idx init_func no_init=false
        local opts=$( getopt -o '' --long "no-init" -n "${FUNCNAME}" -- "$@" )

        eval set -- "${opts}"
        while true; do
            case "${1}" in
            --no-init)
                no_init=true
                shift 1
                ;;

            --)
                shift 1
                break
                ;;
            esac
        done
        modules="${*}"

        for module in ${modules}; do
            if module_included ${module}; then
                continue
            fi

            modfile=$( module_lookup ${module} )
            if [ "${modfile}" ]; then
                idx=${#__module_included_modules__[*]}
                __module_included_modules_file__[${idx}]=${modfile}
                     __module_included_modules__[${idx}]=${module}
                source ${modfile}

                if ! ${no_init}; then
                    init_func=${module##*/}_init
                    if typeset -F ${init_func} &>/dev/null; then
                        eval ${init_func}
                    fi
                fi
            fi
        done
    }

    function module_path() {
        local module=${1}
        local i

        for ((i = 0; i < ${#__module_included_modules__[*]}; i++ )); do
            if [ ${module} = ${__module_included_modules__[${i}]} ]; then
                echo ${__module_included_modules_file__[${i}]}
                return 0
            fi
        done
        return 1
    }

    function module_included_modules() {
        echo ${__module_included_modules__[*]}
    }

    function module_included() {
        local module=${1}
        local name

        for name in ${__module_included_modules__[*]}; do
            if [ ${name} = ${module} ]; then
                return 0
            fi
        done
        return 1
    }

    function module_tree() {
        module_include list

        local modules=() module opts dir file show_paths=false show_functions=false seen
        local opts=$( getopt -o '' --long "functions,paths,module:" -n "${prog}" -- "$@" )

        eval set -- "${opts}"
        while true; do
            case "${1}" in
            --paths)
                show_paths=true
                shift 1
                ;;

            --functions)
                show_functions=true
                shift 1
                ;;

            --module)
                modules+=( ${2} )
                shift 2
                ;;

            --)
                shift 1
                break
                ;;
            esac
        done

        function _module_show_() {
            local module="${1}"
            local file="${2}"
            local str func opts

            str=''
            ${show_paths} && str+="\n"
            str+="$( printf "%-10s" "${module}" )"
            ${show_paths} && str+="$( printf "[%s] " "${file/${HOME}/~}" )"
            echo -e "${str}"
            if ${show_functions}; then
                for func in $(module_functions ${module} ); do
                    str="          ${func}"
                    opts=( $( bash -c "source ${BLIBRC}; module_include ${module}; typeset -f ${func} | grep --color=never '^[[:space:]]*local opts='" | \
                        sed -e 's;.*--long[[:space:]]*\([^ ]*\).*;\1;' \
                            -e 's;";;g' \
                            -e "s;';;g" \
                            -e 's;,; ;g' \
                            -e 's;:;=;g' \
                            -e 's;\<;--;g' | xargs -n1 | sort ) )
                    opts="${opts[*]}"
                    printf "%-30s %s\n"  "${str}" "${opts}"
                done
            fi
        }

        if [ "${modules[*]}" ]; then
            modules=( $( list_sort -u "${modules[*]}" ) )
            for module in ${modules[*]}; do
                file=$( module_lookup ${module} ) || continue
                _module_show_ ${module} ${file}
            done
            return
        fi

        for dir in ${BLIB_PATH//:/ }; do
            for file in $( find ${dir}/lib -name '*.sh'); do
                module=${file#${dir}/lib/}
                module=${module%.sh}
                if list_member "${module}" "${seen}"; then
                    continue
                fi
                seen="$(list_append ${module} "${seen}")"
                _module_show_ ${module} ${file}
            done
        done
    }

    function module_functions() {
        local modules=( ${1} )
        local module dummy fun

        if [ ! "${modules}" ]; then
            modules=$( module_tree )
        fi

        for module in ${modules[*]}; do
            module_include --no-init ${module}
            [ ${#modules[*]} -gt 1 ] && echo "${module}: "
            typeset -F | grep "\<${module##*/}_" | while read dummy dummy fun; do
                echo "   ${fun}"
            done
            echo ""
        done
    }

    function module_list_all() {
        local dir all_modules module
        module_include list

        for dir in ${BLIB_PATH//:/ }; do
            for module in $( cd ${dir}; echo *.sh ); do
                if ! list_member ${module} "${all_modules}"; then
                    all_modules="$(list_append ${module} "${all_modules}")"
                fi
            done
        done

        echo "${all_modules//.sh}"
    }
fi
