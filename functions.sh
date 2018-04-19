uuniq () {
    awk '!x[$0]++'
}

__list_deps_pre () {
sort < "${1}" | sed -e 's#-devel$##' -e 's#-devel ##' | uniq
}

__list_run_deps () {
__list_deps_pre 'run_deps' | grep -E "^${1} "
}

__list_build_deps () {
__list_deps_pre 'build_deps' | grep -E "^${1} "
}

__list_run_deps_rev () {
__list_deps_pre 'run_deps' | grep -E " ${1}$"
}

__list_build_deps_rev () {
__list_deps_pre 'build_deps' | grep -E " ${1}$"
}
