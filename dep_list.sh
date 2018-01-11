#!/bin/bash

# dep_list.sh <package2> <package2> ...
# or
# dep_list.sh

list="$(grep -F '[build]' < graph.dot | sed -e 's/^ *"//' -e 's/" -> "/ /' -e 's/".*//')"
done="$(grep -E '(\[done\]|\[modified\])' < graph.dot | sed -e 's/^ *"//' -e 's/".*$//')"

################################################################################
# recurse <dep>
#
# Recurses through the list of deps and echos all deps back.
#
################################################################################
recurse () {

    echo "${1}"

    grep -E " ${1}$" <<< "${list}" | sed 's/ .*//' | while read -r __dep; do
        recurse "${__dep}"
    done

}

################################################################################
# find_changed <change_1> <change_2> <change_3>
#
# Echo back all affected packages by said input changes
#
################################################################################

find_changed () {

until [ "${#}" = '0' ]; do

    old_dep_list=''
    dep_list="${1}"

    while
        old_dep_list="${dep_list}"
        dep_list="$(grep -E "$(sed 's/^/ /' <<< "${dep_list}")" <<< "${list}" | sed 's/ .*//')
${1}"
        dep_list="$(grep -v '^$' <<< "${dep_list}")"
        echo "${dep_list}"
        ! [ "${old_dep_list}" = "${dep_list}" ]
    do true; done

    recurse "${1}"

    shift

done | sort | uniq

}

if [ "${#}" = 0 ]; then
    order="$(tsort <<< "${list}" | tac)"
    echo "${done}" | grep -Fxv "${order}"
    echo "${order}" | grep -Fx "${done}"
    exit
fi

changed="$(find_changed "${@}")"

affected="$(grep -E "^$(sed 's/$/ /' <<< "${changed}")" <<< "${list}" | tsort | grep -F "${changed}" | tac)"

recompile="$(grep -F "${done}" <<< "${affected}")"

if [ "${2}" = '-r' ]; then
    echo "${recompile}"
    exit
else
    echo 'Recompile:'
    echo
    echo "${recompile}"
fi

echo
echo 'Future:'
echo
grep -Fv "${done}" <<< "${affected}"

exit
