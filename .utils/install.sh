#!/bin/bash

source '.utils/functions/build.sh'
source '.utils/functions/build/state.sh'
source '.utils/functions/build/check.sh'
source '.utils/functions/functions.sh'
source '.utils/functions/install.sh'

#__uninstall

set -x

__list_rundeps_recurse deepin-desktop

exit

if [ "${1}" = '--file' ]; then
    while read -r __line; do
        __packages+=("${__line}")
    done < 'install_list'
    echo ${__packages[@]}
    __install ${__packages[@]}
else
    __install "${@}"
fi

exit
