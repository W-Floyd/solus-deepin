################################################################################
#
# ... | uuniq
#
# Like `sort | uniq`, except it keeps original ordering, keeping the first
# instance of each line
#
# Example:
#
# > echo 'foo
# > bar
# > bar
# > foo' | uuniq
#
# Gives:
#
# foo
# bar
#
################################################################################
uuniq () {
    awk '!x[$0]++'
}

################################################################################
#
# lsdir [/path/to/dir/]
#
# Much like `ls`, except only lists directories. Output is sorted. Input is
# optional, if none is given, '.', the current directory, is used instead.
#
################################################################################

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

lsdir | sed 's|^\./||' | grep -vx common | grep -vx '.git' | grep -vx '.stfolder'

}

################################################################################
#
# ask "Question?" [Y|N]
#
# Asks a yes/no question, with an optional yes/no default. If yes, returns 0, if
# no, returns 1.
#
# To be used in an `if` like so:
# ```
# if ask 'You want to do this?' Y; then
#     echo 'You agreed'
# else
#     echo 'You disagreed'
# fi
# ```
#
################################################################################

ask() {
    # https://gist.github.com/davejamesmiller/1965569
    local prompt default reply

    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
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