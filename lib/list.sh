##
## @module  list
## @desc    Handles various list operations.  The lists are actually
## @desc    bash strings, such as "a bunch of elements" which has four
## @desc    members.
## @desc    
## @desc    Make sure you quote the lists passed as arguments.
## @desc    Elements should not contain spaces!
##

##
## @func    list_member
## @arg     <element> The element to be checked
## @arg     <list> The list (string of elemets) to be checked
## @desc    Checks whether <element> is a member of <list>
## @ret     success or failure
##
function list_member() {
    local elem="${1}"
    local list="${2}"
    local e

    for e in ${list[@]}; do
        [ "${e}" = "${elem}" ] && return 0
    done
    return 1
}

##
## @func    list_append
## @arg     <element> The element to be appended
## @arg     <list> The list to operate on
## @desc    Creates a new list by appending <element> to <list>.
## @out     The new list.
##
function list_append() {
    local elem="${1}"
    local list="${2}"

    if [ "${list}" ]; then
        echo "${list} ${elem}"
    else
        echo "${elem}"
    fi
}

##
## @func    list_delete
## @arg     <element> The element to be deleted
## @arg     <list> The list to operate on
## @desc    Creates a new list by deleting <element> from <list>.
## @out     The new list.
##
function list_delete() {
    local elem="${1}"
    local -a list=( ${2} )
    local i

    for (( i = 0 ; i < ${#list[*]}; i++ )); do
        if [ ${list[${i}]} == "${elem}" ]; then
            unset list[${i}]
        fi
    done

    echo ${list[@]}
}

function _list_to_lines() {
    local list="${1}"

    echo -e ${list//[[:space:]]/\\n}
}

##
## @func    list_sort
## @arg     [sort-args] A list of flags to be passed as-is to sort(1)
## @arg     <list> The list to be sorted
## @desc    Sorts the <list> using sort(1).
## @out     The sorted list
##
function list_sort() {
        local list element sortargs sorted

        while [ $# -gt 1 ]; do
                sortargs="${sortargs} ${1}"
                shift
        done
        list="${1}"

    sorted=$( _list_to_lines "${list}" | sort ${sortargs} )
    echo ${sorted}
}

##
## @func    list_common
## @arg     <list1> The first list
## @arg     <list2> The second list
## @out     A list of common elements (may be empty)
## @desc    Produces a list of the elements common to <list1> and <list2>
##
function list_common() {
    local list1="${1}"
    local list2="${2}"
    local e comm

    for e in ${list1}; do
        if list_member ${e} "${list2}"; then
            comm=$( list_append ${e} "${comm}")
        fi
    done
    echo ${comm}
}

##
## @func    list_head
## @arg     <list> The list in case
## @desc    Gets the first element in <list>
## @out     The first element (may be empty)
##
function list_head() {
    local list=( ${1} )

    echo ${list[0]}
}

##
## @func    list_tail
## @arg     <list> The list in case
## @desc    Gets the last element in <list>
## @out     The last element (may be empty)
##
function list_tail() {
    local list=( ${1} )

    echo ${list[${#list[*]} - 1]}
}

##
## @func    list_same
## @arg     <list1> The first list
## @arg     <list2> The second list
## @desc    Checks whether the two lists are identical
## @ret     success or failure
##
function list_same() {
    local list1="$( list_sort "${1}" )"
    local list2="$( list_sort "${2}" )"

    [ "${list1}" = "${list2}" ] && return 0 || return 1
}
