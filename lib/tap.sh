#!/bin/bash 


_tap_version='1.02'
	
_tap_plan_set=0
_tap_no_plan=0
_tap_skip_all=0
_tap_test_died=0
_tap_expected_tests=0 
_tap_executed_tests=0 
_tap_failed_tests=0
_tap_TODO=


function tap_usage(){
	cat <<'USAGE'
tap-functions: A TAP-producing BASH library

PLAN:
  tap_plan_no_plan
  tap_plan_skip_all [REASON]
  tap_plan_tests NB_TESTS

TEST:
  tap_ok RESULT [NAME]
  tap_okx COMMAND
  tap_is RESULT EXPECTED [NAME]
  tap_isnt RESULT EXPECTED [NAME]
  tap_like RESULT PATTERN [NAME]
  tap_unlike RESULT PATTERN [NAME]
  tap_pass [NAME]
  tap_fail [NAME]

SKIP:
  tap_skip [CONDITION] [REASON] [NB_TESTS=1]

  tap_skip ${feature_not_present} "feature not present" 2 || {
      tap_is ${a} "a"
      tap_is ${b} "b"
  }

TODO:
  Specify TODO mode by setting ${_tap_TODO}:
    _tap_TODO="not implemented yet"
    tap_ok ${result} "some not implemented test"
    unset _tap_TODO

OTHER:
  tap_diag MSG

EXAMPLE:
  #!/bin/bash

  . tap-functions

  tap_plan_tests 7

  me=${USER}
  tap_is ${USER} ${me} "I am myself"
  tap_like ${HOME} ${me} "My home tap_is mine"
  tap_like "`id`" ${me} "My id matches myself"

  /bin/ls ${HOME} 1>&2
  tap_ok $? "/bin/ls ${HOME}"
  # Same thing using tap_okx shortcut
  tap_okx /bin/ls ${HOME}

  [[ "`id -u`" != "0" ]]
  i_am_not_root=$?
  tap_skip ${i_am_not_root} "Must be root" || {
    tap_okx ls /root
  }

  _tap_TODO="figure out how to become root..."
  tap_okx [ "${HOME}" == "/root" ]
  unset _tap_TODO
USAGE
	exit
}

function tap_plan_no_plan(){
	(( _tap_plan_set != 0 )) && "You tried to plan twice!"

	_tap_plan_set=1
	_tap_no_plan=1

	return 0
}


function tap_plan_skip_all(){
	local reason=${1:-''}

	(( _tap_plan_set != 0 )) && _tap_die "You tried to plan twice!"

	_tap_print_plan 0 "Skip ${reason}"

	_tap_skip_all=1
	_tap_plan_set=1
	_tap_exit 0

	return 0
}


function tap_plan_tests(){
	local tests=${1:?}

	(( _tap_plan_set != 0 )) && _tap_die "You tried to plan twice!"
	(( tests == 0 )) && _tap_die "You said to run 0 tests!  You've got to run something."

	_tap_print_plan ${tests}
	_tap_expected_tests=${tests}
	_tap_plan_set=1
    trap _tap_exit EXIT

	return ${tests}
}


function _tap_print_plan(){
	local tests=${1:?}
	local directive=${2:-''}

	echo -n "1..${tests}"
	[[ -n "${directive}" ]] && echo -n " # ${directive}"
	echo
}


function tap_pass(){
	local name=${1}
	tap_ok 0 "${name}"
}


function tap_fail(){
	local name=${1}
	tap_ok 1 "${name}"
}


# This tap_is the workhorse method that actually
# prints the tests result.
function tap_ok(){
	local result=${1:?}
	local name=${2:-''}

	(( _tap_plan_set == 0 )) && _tap_die "You tried to run a test without a plan!  Gotta have a plan."

	_tap_executed_tests=$(( ${_tap_executed_tests} + 1 ))

	if [[ -n "${name}" ]] ; then
		if _tap_matches "${name}" "^[0-9]+$" ; then
			tap_diag "    You named your test '${name}'.  You shouldn't use numbers for your test names."
			tap_diag "    Very confusing."
		fi
	fi

	if (( result != 0 )) ; then
		echo -n "not "
		_tap_failed_tests=$(( _tap_failed_tests + 1 ))
	fi
	echo -n "ok ${_tap_executed_tests}"

	if [[ -n "${name}" ]] ; then
		local ename=${name//\#/\\#}
		echo -n " - ${ename}"
	fi

	if [[ -n "${_tap_TODO}" ]] ; then
		echo -n " # TODO ${_tap_TODO}" ;
		if (( result != 0 )) ; then
			_tap_failed_tests=$(( _tap_failed_tests - 1 ))
		fi
	fi

	echo
	if (( result != 0 )) ; then
		local file='tap-functions'
		local func=
		local line=

		local i=0
		local bt=$(caller ${i})
		while _tap_matches "${bt}" "tap-functions$" ; do
			i=$(( ${i} + 1 ))
			bt=$(caller ${i})
		done
		local backtrace=
		eval $(caller ${i} | (read line func file ; echo "backtrace=\"${file}:${func}() at line ${line}.\""))
			
		local t=
		[[ -n "${_tap_TODO}" ]] && t="(_tap_TODO) "

		if [[ -n "${name}" ]] ; then
			tap_diag "  Failed ${t}test '${name}'"
			tap_diag "  in ${backtrace}"
		else
			tap_diag "  Failed ${t}test in ${backtrace}"
		fi
	fi

	return ${result}
}


function tap_okx(){
	local command="$@"

	local line=
	tap_diag "Output of '${command}':"
	${command} | while read line ; do
		tap_diag "${line}"
	done
	tap_ok ${PIPESTATUS[0]} "${command}"
}


function _tap_equals(){
	local result=${1:?}
	local expected=${2:?}

	if [[ "${result}" == "${expected}" ]] ; then
		return 0
	else 
		return 1
	fi
}


# Thanks to Aaron Kangas for the patch to allow regexp matching
# under bash < 3.
 _tap_bash_major_version=${BASH_VERSION%%.*}
function _tap_matches(){
	local result=${1:?}
	local pattern=${2:?}

	if [[ -z "${result}" || -z "${pattern}" ]] ; then
		return 1
	else
		if (( _tap_bash_major_version >= 3 )) ; then
			eval '[[ "${result}" =~ "${pattern}" ]]'
		else
			echo "${result}" | egrep -q "${pattern}"
		fi
	fi
}


function _tap_is_diag(){
	local result=${1:?}
	local expected=${2:?}

	tap_diag "         got: '${result}'" 
	tap_diag "    expected: '${expected}'"
}


function tap_is(){
	local result=${1:?}
	local expected=${2:?}
	local name=${3:-''}

	_tap_equals "${result}" "${expected}"
	(( $? == 0 ))
	tap_ok $? "${name}"
	local r=$?
	(( r != 0 )) && _tap_is_diag "${result}" "${expected}"
	return ${r} 
}


function tap_isnt(){
	local result=${1:?}
	local expected=${2:?}
	local name=${3:-''}

	_tap_equals "${result}" "${expected}"
	(( $? != 0 ))
	tap_ok $? "${name}"
	local r=$?
	(( r != 0 )) && _tap_is_diag "${result}" "${expected}"
	return ${r} 
}


function tap_like(){
	local result=${1:?}
	local pattern=${2:?}
	local name=${3:-''}

	_tap_matches "${result}" "${pattern}"
	(( $? == 0 ))
	tap_ok $? "${name}"
	local r=$?
	(( r != 0 )) && tap_diag "    '${result}' doesn't match '${pattern}'"
	return ${r}
}


function tap_unlike(){
	local result=${1:?}
	local pattern=${2:?}
	local name=${3:-''}

	_tap_matches "${result}" "${pattern}"
	(( $? != 0 ))
	tap_ok $? "${name}"
	local r=$?
	(( r != 0 )) && tap_diag "    '${result}' matches '${pattern}'"
	return ${r}
}


function tap_skip(){
	local condition=${1:?}
	local reason=${2:-''}
	local n=${3:-1}

	if (( condition == 0 )) ; then
		local i=
		for (( i=0 ; i<${n} ; i++ )) ; do
			_tap_executed_tests=$(( _tap_executed_tests + 1 ))
			echo "ok ${_tap_executed_tests} # tap_skip: ${reason}" 
		done
		return 0
	else
		return
	fi
}


function tap_diag(){
	local msg=${1:?}

	if [[ -n "${msg}" ]] ; then
		echo "# ${msg}"
	fi
	
	return 1
}

	
function _tap_die(){
	local reason=${1:-'<unspecified error>'}

	echo "${reason}" >&2
	_tap_test_died=1
	_tap_exit 255
}


function tap_BAIL_OUT(){
	local reason=${1:-''}

	echo "Bail out! ${reason}" >&2
	_tap_exit 255
}


function _tap_cleanup(){
	local rc=0

	if (( _tap_plan_set == 0 )) ; then
		# tap_diag "Looks like your test died before it could output anything."
		return ${rc}
	fi

	if (( _tap_test_died != 0 )) ; then
		tap_diag "Looks like your test died just after ${_tap_executed_tests}."
		return ${rc}
	fi

	if (( _tap_skip_all == 0 && _tap_no_plan != 0 )) ; then
		_tap_print_plan ${_tap_executed_tests}
	fi

	local s=
	if (( _tap_no_plan == 0 && _tap_expected_tests < _tap_executed_tests )) ; then
		s= ; (( _tap_expected_tests > 1 )) && s=s
		local extra=$(( _tap_executed_tests - _tap_expected_tests ))
		tap_diag "Looks like you planned ${_tap_expected_tests} test${s} but ran ${extra} extra."
		rc=-1 ;
	fi

	if (( _tap_no_plan == 0 && _tap_expected_tests > _tap_executed_tests )) ; then
		s= ; (( _tap_expected_tests > 1 )) && s=s
		tap_diag "Looks like you planned ${_tap_expected_tests} test${s} but only ran ${_tap_executed_tests}."
	fi

	if (( _tap_failed_tests > 0 )) ; then
		s= ; (( _tap_failed_tests > 1 )) && s=s
		tap_diag "Looks like you failed ${_tap_failed_tests} test${s} of ${_tap_executed_tests}."
	fi

	return ${rc}
}


function _tap_exit_status(){
	if (( _tap_no_plan != 0 || _tap_plan_set == 0 )) ; then
		return ${_tap_failed_tests}
	fi

	if (( _tap_expected_tests < _tap_executed_tests )) ; then
		return $(( _tap_executed_tests - _tap_expected_tests  ))
	fi

	return $(( _tap_failed_tests + ( _tap_expected_tests - _tap_executed_tests )))
}


function _tap_exit(){
	local rc=${1:-''}
	if [[ -z "${rc}" ]] ; then
		_tap_exit_status
		rc=$?
	fi

	_tap_cleanup
	local alt_rc=$?
	(( alt_rc != 0 )) && rc=${alt_rc}
	trap - EXIT
	exit ${rc}
}

