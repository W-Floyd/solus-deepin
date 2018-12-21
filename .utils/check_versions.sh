#!/bin/bash

################################################################################

__should_exit='0'

################################################################################

while read -r __program; do
    if ! which "${__program}" &> /dev/null; then
        echo "Sorry, '${__program}' is not available.'"
        __should_exit='1'
    fi
done <<< "cuppa"

if [ "${__should_exit}" = '1' ]; then
    exit 1
fi

################################################################################

source 'functions.sh'

################################################################################

__list_packages | grep -xvf 'ignore_list' | sort | while read -r __package; do

    __source="$(grep -x --after-context=1 'source     :' "${__package}/package.yml" | sed -e '1d' -e 's/^.*- //')"
    __version="$(grep -E '^version    : ' "${__package}/package.yml" | sed -e 's/( |\n )*$//' -e 's/.* //')"

    if grep -qE '^git|' <<< "${__source}"; then
        __source="$(sed -e 's/^git|//' -e 's/ .*//' -e 's/\.git$//' <<< "${__source}")"
    fi

    __url="${__source}/archive/${__version}.tar.gz"

    echo -e "Checking for updates to: \e[34m${__package}\e[39m"
    __current_version="$(cuppa l "${__url}" | grep 'Version   :' | sed -e 's/( |\n )*$//' -e 's/.* //')"
    if [ "${__version}" = "${__current_version}" ]; then
        echo -e "\t\e[32mUp to date\e[39m (${__version})"
    else
        echo -e "\t\e[31m${__version}\e[39m ⮞ \e[32m${__current_version}\e[39m"
    fi


done

exit
