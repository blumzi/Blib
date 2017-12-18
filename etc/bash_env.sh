#!/bin/bash

#
# When the environment variable BASH_ENV points to this file, each and every
#  bash script will run it as soon as it starts, see man bash(1).
#

BASH_ENV=
if [ -r /etc/bash_env ]; then
    BASH_ENV=/etc/bash_env
elif [ -r ~/.blib/bash_env ]; then
    BASH_ENV=~/.blib/bash_env
fi

if [ "${BASH_ENV}" ]; then
    export BASH_ENV
    source ${BASH_ENV}
fi

if [ "${BLIB_DEBUG}" ]; then
    export PS4='+ \d \t ${FUNCNAME:-main}@/${BASH_SOURCE}:${LINENO} '
    set -x
fi
