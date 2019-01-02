################################################################################
#
# __check_is_package <package>
#
# Checks if a given package is real.
#
################################################################################

__check_is_package() {

    if __list_packages_devel "${1}" | grep -qx "${1}"; then
        return 0
    fi

    return 1

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
# __mark_built <package>
#
# Marks a package as being built
#
################################################################################

__mark_built() {
    if ! [ -d '.tmp/built/' ]; then
        mkdir '.tmp/built/'
    fi
    touch ".tmp/built/${1%-devel}"
}

################################################################################
#
# __check_built_eopkg <package>
#
# Checks if a package is built, according to eopkg files, 0 on true, 1 on false.
#
################################################################################

__check_built_eopkg() {

    if [ -z "$(find "./${1%-devel}/" -iname '*.eopkg')" ]; then
        return 1
    fi

    __current_build="$(find "./${1%-devel}/" -iname '*.eopkg' | sort -n | sed '$!d' | sed 's#.*-\([0-9]*\)-1-x86_64\.eopkg$#\1#')"
    __target_build="$(grep -Ex '^release    : .*' "${1%-devel}/package.yml" | sed 's/.* //')"

    if ! [ "${__current_build}" = "${__target_build}" ]; then
        return 1
    fi

    __mark_built "${1}"

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
    if [ -e ".tmp/built/${1%-devel}" ]; then
        return 0
    fi
    return 1
}

################################################################################
#
# __check_built <package>
#
# Checks if a package is built, 0 on true, 1 on false.
#
################################################################################

__check_built() {
    if __check_marked_built "${1}" || __check_built_eopkg "${1}"; then
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
    touch ".tmp/failed/${1%-devel}"
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
    if [ -e ".tmp/failed/${1%-devel}" ]; then
        return 0
    fi
    return 1
}

################################################################################
#
# __mark_failed_chain_rundeps <package>
#
# Checks if a package has any rundeps marked as failed, cascading down.
#
################################################################################

__mark_failed_chain_rundeps() {

    __error='0'

    if ! [ -d '.tmp/failed/' ]; then
        mkdir '.tmp/failed/'
    fi

    if [ -e ".tmp/chainrun/${1%-devel}" ]; then
        return "$(cat ".tmp/chainrun/${1%-devel}")"
    fi

    __check_failed "${1}" && __error='1'

    if ! __check_built "${1}"; then
        (__mark_failed_chain "${1}") || __error='1'
    fi

    while read -r __package; do

        if ! [ -z "${__package}" ]; then

            (__mark_failed_chain_rundeps "${__package}") || __error='1'

        fi

    done < <(__list_rundeps "${1}" | sed '/^$/d')

    echo "${__error}" > ".tmp/chainrun/${1%-devel}"

    if [ "${__error}" = '1' ]; then
        return 1
    fi

}

################################################################################
#
# __mark_failed_chain <package>
#
# Checks if a package has any builddeps marked as failed, or any builddeps
# rundeps marked as failed
#
################################################################################

__mark_failed_chain() {

    __error='0'

    if ! [ -d '.tmp/failed/' ]; then
        mkdir '.tmp/failed/'
    fi

    if [ -e ".tmp/chainbuild/${1%-devel}" ]; then
        return "$(cat ".tmp/chainbuild/${1%-devel}")"
    fi

    __check_failed "${1}" && __error='1'

    while read -r __builddep; do

        if ! [ -z "${__builddep}" ]; then

            (__mark_failed_chain "${__builddep}") || __error='1'

            (__mark_failed_chain_rundeps "${__builddep}") || __error='1'

        fi

    done < <(__list_builddeps "${1}" | sed '/^$/d')

    echo "${__error}" > ".tmp/chainbuild/${1%-devel}"

    if [ "${__error}" = '1' ]; then
        __mark_failed "${1}"
        return 1
    fi

    # TODO
    # Check all builddeps, and builddeps of theirs (recurse this function)
    # Also check all rundeps of builddeps, and rundeps of those rundeps
    # If any rundeps of builddeps aren't built, recurse on those also.
    # If any fail, the whole chain from there up does.

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
    elif [ "$(cat ./.tmp/building)" = "${1%-devel}" ]; then
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
    if ! [ -d '.tmp/displayed/' ]; then
        mkdir '.tmp/displayed/'
    fi
    touch ".tmp/displayed/${1%-devel}"
}

################################################################################
#
# __check_displayed <package>
#
# Checks if a package has already been displayed, 0 on true, 1 on false.
#
################################################################################

__check_displayed() {
    if ! [ -d '.tmp/displayed/' ]; then
        mkdir '.tmp/displayed/'
        return 1
    elif [ -e ".tmp/displayed/${1%-devel}" ]; then
        return 0
    fi
    return 1
}
