#!/bin/bash -e

################################################################################

source '.utils/functions/functions.sh'

################################################################################

if [ "${1}" = '--piped' ]; then
    __piped_input="$(cat)"
    shift
fi

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

    "${__script}" ${@} <<< "${__piped_input}" || exit 1

fi

################################################################################

exit
