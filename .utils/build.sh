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

tput cup 0 0
tput clear

mkdir -p '.tmp/chainrun/'
mkdir -p '.tmp/chainbuild/'
__mark_failed_chain "${1}"
__mark_failed_chain_rundeps "${1}"
rm -r '.tmp/chainrun/'
rm -r '.tmp/chainbuild/'

__redraw "${1}" build end

__list_func() {
    {
        __tsort_prepare | sed -e 's/-devel / /' -e 's/-devel$//' | tsort | tac
        echo "${1}"
        __list_rundeps "${1}"
    } | __uuniq | grep -Fxvf <(__list_built) | grep -Fxvf <(__list_failed) | sed '/^$/d'
}

__list="$(__list_func "${1}")"

until [ -z "${__list}" ]; do

    echo "${__list}" | sed -e '/^$/d' -e '1!d' | while read -r __package; do

        __error='0'

        rm .tmp/displayed/*
        echo "${__package}" > '.tmp/building'
        __redraw "${1}" build end > '.tmp/output'
        tput clear
        tput cup 0 0
        cat '.tmp/output'
        '.utils/subutils/build/real_build.sh' "${__package}" || __error='1'

        rm '.tmp/building'

        if [ "${__error}" = '1' ]; then

            mkdir -p '.tmp/chainrun/'
            mkdir -p '.tmp/chainbuild/'
            __mark_failed_chain "${1}"
            __mark_failed_chain_rundeps "${1}"
            rm -r '.tmp/chainrun/'
            rm -r '.tmp/chainbuild/'

        fi

    done

    __list="$(__list_func "${1}")"

done

rm .tmp/displayed/*
__redraw "${1}" build end > '.tmp/output'
tput clear
tput cup 0 0
cat '.tmp/output'

if __check_failed "${1}" ; then
    exit 1
fi

exit
