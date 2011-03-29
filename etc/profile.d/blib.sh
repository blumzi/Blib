#!/bin/bash

BLIB_BASE=/usr/share/blib

if [ ! "${BLIB_PATH}" ]; then
    export BLIB_PATH=${BLIB_BASE}
fi

export     BLIB_ETC=${BLIB_BASE}/etc
export BLIB_COMMAND="btool"
export    BLIB_BDOC="bdoc"

for dir in ${BLIB_PATH//:/ }; do
    if [ -r ${dir}/lib/module.sh ]; then
        source ${dir}/lib/module.sh
        if typeset -F module_include >/dev/null; then
            break
        fi
    fi
done

if ! typeset -F module_include >/dev/null; then
    return
fi
unset dir

for dir in ${BLIB_PATH//:/ }; do
    if [ -d ${dir}/bin ] && [[ :${PATH}: != *:${dir}:* ]]; then
        export PATH=${PATH}:${dir}/bin
    fi
done
unset dir

export PS4='+ \D{%Y %h %d %T} \H ${FUNCNAME:-main}@${BASH_SOURCE#${BLIB_BASE}/}:${LINENO} '

module_include command

function _blibtool() {
    local cmdline=( ${COMP_WORDS[@]} )
    local cmd=${cmdline[0]}
    local cur=${cmdline[COMP_CWORD]}
    local main_flags subpath fullpath options=() opt

    case ${COMP_WORDS[0]} in
    ${BLIB_COMMAND}) main_flags="--debug --help"               ;;
    ${BLIB_BDOC})    main_flags="--help --module= --function=" ;;
    esac

    for (( i = 1; i <  ${COMP_CWORD}; i++ )); do
        if [[ ${cmdline[i]} == -* ]]; then
            continue
        fi
        subpath+="${cmdline[i]}/"
    done
    subpath=${subpath%/}
    fullpath=$(command_path_lookup ${subpath//\// })

    if [[ "${cur}" == -* ]]; then           # we're in the middle of a flag
        if [ "${subpath}" ]; then           # it's a subcommand's flag
            if [ -x ${fullpath} ]; then
                for opt in $( command_getopts ${fullpath} ); do
                    [[ "${opt}" == ${cur}* ]] && options+=(${opt})
                done
            fi
        else                                # it's the main program's flag
            options=( ${main_flags} )
        fi
    else                                    # we're in the middle of a subcommand
        if [ -d ${fullpath} ]; then         # up till now we have only directories
            for name in $( cd ${fullpath}; echo *); do
                if [ ${name} = ${BLIB_COMMAND} ]; then
                    continue
                fi
                if [ -d ${fullpath}/${name} ] || [ -x ${fullpath}/${name} ]; then
                    if [ "${cur}" ]; then   # we have a start of a word
                        if [[ "${name}" == ${cur}* ]]; then
                            options+=( ${name} )
                        fi
                    else
                        options+=( ${name} )
                    fi
                fi
            done
        else                                # the last element is a subcommand
            for opt in $( command_getopts ${fullpath} ); do
                [[ "${opt}" == ${cur}* ]] && options+=( ${opt} )
            done
        fi
    fi
    COMPREPLY=( $(compgen -W "${options[*]}" -- $cur ) )
}

complete -o default -o nospace -F _blibtool ${BLIB_COMMAND} ${BLIB_COMMAND}
complete -o default -o nospace -F _blibtool ${BLIB_BDOC}    ${BLIB_BDOC}
