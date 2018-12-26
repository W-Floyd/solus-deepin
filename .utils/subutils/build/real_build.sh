#!/bin/bash

source '.utils/functions/functions.sh'
source '.utils/functions/build.sh'
source '.utils/functions/build/check.sh'
source '.utils/functions/build/copy.sh'
source '.utils/functions/build/state.sh'
source '.utils/functions/build/tree.sh'
source '.utils/functions/color.sh'
source '.utils/variables/build_symbols.sh'

find '/var/lib/solbuild/local/' -iname '*.eopkg' | while read -r __file; do
    rm "${__file}"
done

__recurse_copy_eopkg "${1}"

__build_package "${1}"

if __check_built "${1}"; then
    __mark_built "${1}"
    __rundeps_store "${1}"
else
    __mark_failed "${1}"
    exit 1
fi

exit
