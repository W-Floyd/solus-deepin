################################################################################
#
# [...] | __catecho
#
# cats input if available, but does not block for it.
#
################################################################################

__catecho() {
    if read -r -t 0; then
        cat
    fi
}

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
# > foo
# > bar' | uuniq
#
# Gives:
#
# foo
# bar
#
################################################################################
__uuniq() {
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

lsdir() {
    if [ -z "${1}" ]; then
        find -L . -maxdepth 1 -mindepth 1 -type d | sort
    else
        find -L "${1}" -maxdepth 1 -mindepth 1 -type d | sort
    fi
}

################################################################################
#
# __list_packages
#
# Lists all packages.
#
################################################################################

__list_packages() {

    lsdir | sed 's|^\./||' | grep -Fvx 'common
.git
.stfolder
.bin
.tmp
.utils
.vscode
.rundeps'

}

################################################################################
#
# __list_packages_devel
#
# Lists all packages, along with -devel versions.
#
################################################################################

__list_packages_devel() {

    __list_packages | sed 's/\(.*\)/\1\n\1-devel/'

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
        read reply < /dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y* | y*) return 0 ;;
            N* | n*) return 1 ;;
        esac

    done
}

################################################################################
# [...] | __yaml2json [options]
#
# Same as `yaml2json`, just that it wraps it up nicely to download a binary if
# needed, and if not, use system
#
################################################################################

__yaml2json() {

    __bin_file='/usr/bin/yaml2json'
    if ! [ -e "${__bin_file}" ]; then
        __bin_file='.bin/yaml2json'
        if ! [ -e "${__bin_file}" ]; then
            mkdir -p '.bin/'
            wget -q 'https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_linux_amd64' --output-document='.bin/yaml2json' || {
                echo 'Failed to obtain yaml2json.' >&2
                exit 1
            }
            chmod +x "${__bin_file}"
        fi
    fi
    cat | "${__bin_file}" ${@}
}

################################################################################
# [...] | __jq [options]
#
# Same as `jq`, just that it wraps it up nicely to download a package if needed.
#
################################################################################

__jq() {

    if ! which jq &> /dev/null; then
        echo 'We need to install jq' >&2
        eopkg it jq || {
            echo 'Failed to obtain jq.' >&2
            exit 1
        }
    fi
    cat | jq ${@}
}

################################################################################
#  __xmllint [options]
#
# Same as `__xmllint`, just that it wraps it up nicely to download a package if
# needed.
#
################################################################################

__xmllint() {
    if ! which xmllint &> /dev/null; then
        echo 'We need to install xmllint' >&2
        eopkg it libxml2 || {
            echo 'Failed to obtain libxml2.' >&2
            exit 1
        }
    fi
    xmllint ${@}
}

################################################################################
#
# __hash_dir <dir>
#
# Creates a single hash for a directory.
#
################################################################################

__hash_dir() {
    find "${1}" -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum
}

################################################################################
#
# __hash_state
#
# A single function to give a hash for the current state of the build.
#
################################################################################

__hash_state() {

    __hash_dir './.tmp/'

}
