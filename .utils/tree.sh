#!/bin/bash

source '.utils/functions/functions.sh'
source '.utils/functions/build.sh'
source '.utils/functions/build/state.sh'
source '.utils/functions/build/tree.sh'
source '.utils/functions/build/copy.sh'
source '.utils/functions/color.sh'
source '.utils/functions/build/check.sh'
source '.utils/variables/color.sh'
source '.utils/variables/build_symbols.sh'

mkdir -p '.rundeps/'

__check_state "${1}"

__redraw "${1}" build end

exit
