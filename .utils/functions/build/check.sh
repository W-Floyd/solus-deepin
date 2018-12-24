################################################################################
#
# __check_deps <package>
#
# Scans through package deps and checks statuses.
#
################################################################################

__check_deps() {

    {
        __list_builddeps "${1}"
        __list_rundeps "${1}"
    } | sort | uniq | while read -r __package; do

        if __check_failed "${__package}"; then
            __mark_failed "${1}"
        fi

        __check_deps "${__package}"

        __check_built "${__package}" || true

    done

}

################################################################################
#
# __check_rundeps_built <package>
#
# Scans through package rundeps and checks if all of them are built, including
# rundeps of rundeps
#
################################################################################

__check_rundeps_built() {

    __list_rundeps "${1}" | while read -r __package; do

        if ! __check_built "${__package}"; then
            return 1
        fi

        if ! __check_rundeps_built "${__package}"; then
            return 1
        fi

    done || return 1

    return 0

}

################################################################################
#
# __check_ready_to_build <package>
#
# Scans through package deps and checks if it is cleared to build. Returns 0 if
# all clear, 1 if not clear.
#
################################################################################

__check_ready_to_build() {

    if ! __check_failed "${1}" && ! __check_built "${1}"; then
        touch '.dont_quit'
    fi

    if [ -e './.tmp/building' ] || __check_built "${1}" || __check_failed "${1}"; then
        return 1
    fi

    __list_builddeps "${1}" | while read -r __package; do

        if ! __check_built "${__package}"; then
            return 1
        fi

        __list_rundeps "${__package}" | while read -r __run_package; do

            if ! __check_built "${__run_package}" || ! __check_rundeps_built "${__run_package}"; then
                return 1
            fi

        done

    done || return 1

    return 0

}

################################################################################
#
# __mark_checked <package>
#
# Marks a package as being checked for being built
#
################################################################################

__mark_built() {
    if ! [ -d '.tmp/built/' ]; then
        mkdir '.tmp/built/'
    fi
    touch ".tmp/built/$(sed 's/-devel$//' <<< "${1}")"
}

################################################################################
#
# __check_built <package>
#
# Checks if a package is built, 0 on true, 1 on false.
#
################################################################################

__check_built() {

    __check_marked_built "${1}" && return 0

    if [ -z "$(find "./$(sed 's/-devel$//' <<< "${1}")/" -iname '*.eopkg')" ]; then
        return 1
    fi

    __current_build="$(find "./$(sed 's/-devel$//' <<< "${1}")/" -iname '*.eopkg' | sed 's#.*-\([0-9]*\)-1-x86_64\.eopkg$#\1#' | sort | uniq)"
    __target_build="$(grep -Ex '^release    : .*' "${1}/package.yml" | sed 's/.* //')"

    if ! [ "${__current_build}" = "${__target_build}" ]; then
        return 1
    fi

    __mark_built

    return 0
}

################################################################################
#
# __check_marked_built <package>
#
# Checks if a package has been checked for building, 0 on true, 1 on false.
#
################################################################################

__check_marked_built() {
    if ! [ -d '.tmp/built/' ]; then
        mkdir '.tmp/built/'
        return 1
    fi
    if [ -e ".tmp/built/$(sed 's/-devel$//' <<< "${1}")" ]; then
        return 0
    fi
    return 1
}

################################################################################
#
# __mark_failed <package>
#
# Marks a package as failed building
#
################################################################################

__mark_failed() {
    if ! [ -d '.tmp/failed/' ]; then
        mkdir '.tmp/failed/'
    fi
    touch ".tmp/failed/$(sed 's/-devel$//' <<< "${1}")"
}

################################################################################
#
# __check_failed <package>
#
# Checks if a package has been marked as failed, 0 on true, 1 on false.
#
################################################################################

__check_failed() {
    if ! [ -d '.tmp/failed/' ]; then
        mkdir '.tmp/failed/'
        return 1
    fi
    if [ -e ".tmp/failed/$(sed 's/-devel$//' <<< "${1}")" ]; then
        return 0
    fi
    return 1
}

################################################################################
#
# __check_building <package>
#
# Checks if a package is currently building, 0 on true, 1 on false.
#
################################################################################

__check_building() {
    if ! [ -e './.tmp/building' ]; then
        return 1
    elif [ "$(cat ./.tmp/building)" = "${1}" ]; then
        return 0
    fi
    return 1
}

################################################################################
#
# __mark_displayed <package>
#
# Marks if a package has already been displayed
#
################################################################################

__mark_displayed() {
    touch ".tmp/displayed/${1}"
}


################################################################################
#
# __check_displayed <package>
#
# Checks if a package has already been displayed, 0 on true, 1 on false.
#
################################################################################

__check_displayed() {
    if [ -e ".tmp/displayed/${1}" ]; then
        return 0
    fi
    return 1
}
