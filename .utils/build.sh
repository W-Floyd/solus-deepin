#!/bin/bash

source '.utils/functions/build.sh'
source '.utils/functions/build/check.sh'
source '.utils/functions/build/state.sh'
source '.utils/functions/build/tree.sh'
source '.utils/functions/color.sh'
source '.utils/functions/functions.sh'
source '.utils/variables/build_symbols.sh'
source '.utils/variables/color.sh'
source '.utils/functions/abi.sh'

export PS4='Line ${LINENO}: '

if [ -d '.tmp/' ]; then
    rm -r '.tmp/'
fi

mkdir -p '.tmp/'

mkdir -p '.tmp/log/'
mkdir -p '.tmp/failed/'
mkdir -p '.rundeps/'

__piped_input="$(__catecho)"

__inputs="$(
    until [ "${#}" = '0' ]; do
        echo "${1}"
        shift
    done
)
${__piped_input}"

__inputs="$(sed '/^$/d' <<< "${__inputs}")"

while read -r __input; do
    __check_state "${__input}"
done <<< "${__inputs}"

tput cup 0 0
tput clear

mkdir -p '.tmp/chainrun/'
mkdir -p '.tmp/chainbuild/'
while read -r __input; do
    __mark_failed_chain "${__input}"
    __mark_failed_chain_rundeps "${__input}"
done <<< "${__inputs}"
rm -r '.tmp/chainrun/'
rm -r '.tmp/chainbuild/'

while read -r __input; do
    __redraw "${__input}" build end
done <<< "${__inputs}" | cut -c 2-

__list_func() {
    {
        __tsort_prepare | sed -e 's/-devel / /' -e 's/-devel$//' | tsort | tac
        echo "${1}"
        __list_rundeps "${1}"
    } | __uuniq | grep -Fxvf <(__list_built) | grep -Fxvf <(__list_failed) | sed '/^$/d'
}

__list="$(
    while read -r __input; do
        __list_func "${__input}"
    done <<< "${__inputs}"
)"

until [ -z "${__list}" ]; do

    echo "${__list}" | sed -e '/^$/d' -e '1!d' | while read -r __package; do

        __error='0'

        rm .tmp/displayed/*
        echo "${__package}" > '.tmp/building'
        while read -r __input; do
            __redraw "${__input}" build end
        done <<< "${__inputs}" > '.tmp/output' | cut -c 2-
        tput clear
        tput cup 0 0
        cat '.tmp/output'
        '.utils/subutils/build/real_build.sh' "${__package}" || __error='1'

        rm '.tmp/building'

        if [ "${__error}" = '1' ]; then

            mkdir -p '.tmp/chainrun/'
            mkdir -p '.tmp/chainbuild/'
            while read -r __input; do
                __mark_failed_chain "${__input}"
                __mark_failed_chain_rundeps "${__input}"
            done <<< "${__inputs}"
            rm -r '.tmp/chainrun/'
            rm -r '.tmp/chainbuild/'

        fi

    done

    __list="$(
        while read -r __input; do
            __list_func "${__input}"
        done <<< "${__inputs}"
    )"

done

rm .tmp/displayed/*
while read -r __input; do
    __redraw "${__input}" build end
done <<< "${__inputs}" > '.tmp/output' | cut -c 2-
tput clear
tput cup 0 0
cat '.tmp/output'

while read -r __input; do
    if __check_failed "${__input}"; then
        exit 1
    fi
done <<< "${__inputs}" > '.tmp/output'

exit
