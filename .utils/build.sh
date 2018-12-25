#!/bin/bash

source '.utils/functions.sh'
source '.utils/functions/build.sh'
source '.utils/functions/build/state.sh'
source '.utils/functions/build/tree.sh'
source '.utils/functions/color.sh'
source '.utils/functions/build/check.sh'
source '.utils/variables/color.sh'
source '.utils/variables/build_symbols.sh'

mkdir -p '.tmp/log/'
mkdir -p '.tmp/failed/'
mkdir -p '.rundeps/'

__check_state "${1}"

#tput cup 0 0
#tput clear

mkdir -p '.tmp/chainrun/'
mkdir -p '.tmp/chainbuild/'

__mark_failed_chain "${1}"
__mark_failed_chain_rundeps "${1}"

rm -r '.tmp/chainrun/'
rm -r '.tmp/chainbuild/'

__redraw "${1}" build end

__list="${1}"

until [ -z "${__list}" ]; do
    __list="$(
        __tsort_prepare | sed -e 's/-devel / /' -e 's/-devel$//' | tsort | tac | grep -Fxv "$(__list_built)" | sed '/^$/d'
    )"
    echo "${__list}" | sed '/^$/d' | while read -r __package; do

        rm .tmp/displayed/*
        echo "${__package}" > '.tmp/building'
        __redraw "${1}" build end > '.tmp/output'
        tput clear
        tput cup 0 0
        cat '.tmp/output'
        '.utils/subutils/build/real_build.sh' "${__package}"
        rm '.tmp/building'
    done

done

__redraw "${1}" build end > '.tmp/output'
tput clear
tput cup 0 0
cat '.tmp/output'

exit
