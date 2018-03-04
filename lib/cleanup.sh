##
## @module  cleanup
## @author  Arie Blumenzweig
## @desc
## @desc    Maintains a list of cleanup functions that will be called
## @desc     when the process exits
## @desc
##

_cleanup_registered_functions=()

##
## @func    cleanup_register
## @desc    Registers a function to be call at process exit-time (with no arguments)
## @arg     <func> The function's name
##
function cleanup_register() {
    local func="${1}"

    if [ "${func}" ]; then
        _cleanup_registered_functions+=( ${func} )
    fi
}

##
## @func    cleanup_run
## @desc    Calls the cleanup functions, in the order they were registered.
## @desc     This function is intrinsically called by the btool, no need to 
## @desc     call it explicitly.
##
function cleanup_run() {
    local func

    for func in ${_cleanup_registered_functions[*]}; do
        ${func}
    done
}
