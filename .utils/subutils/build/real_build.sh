#!/bin/bash

source '.utils/functions.sh'
source '.utils/functions/build.sh'
source '.utils/functions/build/check.sh'
source '.utils/functions/build/copy.sh'

set -x

echo "${1}" > './.tmp/building'

find '/var/lib/solbuild/local/' -iname '*.eopkg' | while read -r __file; do
    rm "${__file}"
done

__recurse_copy_eopkg "${1}"

__build "${1}"

rm './.tmp/building'

if __check_built "${1}"; then
    __mark_built "${1}"
    __list_rundeps_eopkg_store "${1}"
else
    __mark_failed
fi

exit
