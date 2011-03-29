#!/bin/bash

#
# This is a debug helper file. When the environment variable BASH_ENV 
#  points to this file, each and every bash script will run
#  it as soon as it starts, see man bash(1).
#
export BASH_ENV=${BLIB_BASE}/etc/bash_env
export PS4='+ \d \t ${FUNCNAME:-main}@${BASH_SOURCE}:${LINENO} '
echo -e "\n ${0} ${@}\n"
set -x
