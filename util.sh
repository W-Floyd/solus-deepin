#!/bin/bash -e

################################################################################

if [ -d '.tmp/' ]; then
    rm -r '.tmp/'
fi

mkdir -p '.tmp/'

if [ -z "${1}" ]; then
    echo 'No action given'
    exit 1
fi

__action="${1}"
shift

__script="./.utils/${__action}.sh"

if ! [ -e "${__script}" ]; then
    echo "Action '${__action}' does not exist"
    exit 1
else
    "${__script}" ${@} || exit 1
fi

################################################################################

exit
