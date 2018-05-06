uuniq () {
    awk '!x[$0]++'
}

__list_deps_pre () {
sort < "${1}" | sed -e 's#-devel$##' -e 's#-devel ##' | uniq
}

__list_deps_true () {
sort < "${1}" | uniq 
}

__list_run_deps () {
if [ "${1}" = '--true' ]; then
    shift
    __list_deps_true 'run_deps' | grep -E "^${1} "
else
    __list_deps_pre 'run_deps' | grep -E "^${1} "
fi
}

__list_build_deps () {
if [ "${1}" = '--true' ]; then
    shift
    __list_deps_true 'build_deps' | grep -E "^${1} "
else
    __list_deps_pre 'build_deps' | grep -E "^${1} "
fi
}

__list_run_deps_rev () {
if [ "${1}" = '--true' ]; then
    shift
    __list_deps_pre 'run_deps' | grep -E " ${1}$"
else
    __list_deps_true 'run_deps' | grep -E " ${1}$"
fi
}

__list_build_deps_rev () {
if [ "${1}" = '--true' ]; then
    shift
    __list_deps_pre 'build_deps' | grep -E " ${1}$"
else
    __list_deps_true 'build_deps' | grep -E " ${1}$"
fi
}
