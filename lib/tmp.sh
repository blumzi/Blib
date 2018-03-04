module_include cleanup

function tmp_mkfile() {
    declare prefix=${1}
    declare file=/tmp/${prefix}.$$
    declare tmp_list_file=/tmp/.mktmp.${BLIB_PID}

    echo ${file} >> ${tmp_list_file}
    echo ${file}
}

function tmp_cleanup() {
    declare tmp_list_file=/tmp/.mktmp.${BLIB_PID}

    if [ -f ${tmp_list_file} ]; then
        rm -rf $(< ${tmp_list_file})
        rm -f ${tmp_list_file}
    fi
}

function tmp_init() {
    cleanup_register tmp_cleanup
}
