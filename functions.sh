uuniq () {
    awk '!x[$0]++'
}

lsdir () {
if [ -z "${1}" ]; then
    find . -maxdepth 1 -mindepth 1 -type d | sort
else
    find "${1}" -maxdepth 1 -mindepth 1 -type d | sort
fi
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

__list_packages () {

lsdir | grep -v common | grep -v 'git' | grep -v '\.stfolder' | sed 's|^\./||'

}

################################################################################
# __upgrade [package] [version]
#
# Commits an upgrade to a given package with a given version.
#
################################################################################

__upgrade () {
    __package="${1}"
    __version="${2}"
    git add "${__package}/"
    git commit -m "${__package}: Upgrade to ${__version}"
}

################################################################################
# __rebuild [package]
#
# Commits a bump and rebuild to a given package.
#
################################################################################

__rebuild () {
    __package="${1}"
    git add "${__package}/"
    git commit -m "${__package}: Bump and rebuild."
}

################################################################################
# __list
#
# List all packages that have been built but changes are yet to be commited
#
################################################################################

__list () {
find . -iname '*.eopkg' | sed -e 's#^\./##' -e 's#/.*##' | sort | uniq | grep -Fxf <(git status --short | sed -e 's#^ M ##' -e 's#/.*##' | sort | uniq)
}