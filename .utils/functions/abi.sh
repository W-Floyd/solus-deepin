################################################################################
#
# __list_abi_provided <package>
#
# Lists all the ABI names provided by a given package, without versions.
#
################################################################################

__list_abi_provided() {

    if [ -e "${1%-devel}/abi_symbols" ]; then
        sed -e 's/\([^:]*\):.*/\1/' -e 's/\.[0-9]*$//' < "${1%-devel}/abi_symbols" | sort | uniq
    fi

}

################################################################################
#
# __list_abi_used <package>
#
# Lists all the ABI names used by a given package, without versions.
#
################################################################################

__list_abi_used() {

    if [ -e "${1%-devel}/abi_used_libs" ]; then
        sed -e 's/\.[0-9]*$//' < "${1%-devel}/abi_used_libs" | sort | uniq
    fi

}

################################################################################
#
# __abi_version_provided <package> <abi>
#
# Prints the ABI version provided by a given package for a given symbol.
#
################################################################################

__abi_version_provided() {

    if ! [ -e "${1%-devel}/abi_symbols" ]; then
        echo "No ABI's provided by ${1%-devel}"
        return 1
    fi

    sed -e 's/\([^:]*\):.*/\1/' < "${1%-devel}/abi_symbols" | sort | uniq | grep -xE "^${2}.[0-9]*$" | sed 's/^.*\.\([0-9]*\)$/\1/'

}

################################################################################
#
# __abi_version_provided <package> <abi>
#
# Prints the ABI version provided by a given package for a given symbol.
#
################################################################################

__abi_version_used() {

    if [ -e "${1%-devel}/abi_used_libs" ]; then
        sort < "${1%-devel}/abi_used_libs" | uniq | grep -xE "^${2}.[0-9]*$" | sed 's/^.*\.\([0-9]*\)$/\1/'
    fi

}

################################################################################
#
# __bump_abi_deps <package>
#
# Bumps all deps of a package if needed, taking into account abi versions, and
# the use of them by other packages.
#
################################################################################

__bump_abi_deps() {

    source '.utils/functions/build.sh'

    if [ -e "${1%-devel}/abi_symbols" ]; then
        if ! [ -z "$(git diff --name-only "./${1%-devel}/" | grep -Fx "${1%-devel}/abi_symbols")" ]; then

            while read -r __abi; do
                grep -lrE "^${__abi}\.[0-9]*$" | grep '/abi_used_libs' | sed 's#/.*##' | while read -r __package; do
                    __list_abi_used "${__package}" | grep -Fxf <(__list_abi_provided "${1}") | while read -r __abi; do

                        if ! [ "$(__abi_version_provided "${1}" "${__abi}")" = "$(__abi_version_used "${__package}" "${__abi}")" ]; then

                            if [ -e ".tmp/built/${__package}" ]; then
                                rm ".tmp/built/${__package}"
                            fi

                            cd "${__package%-devel}"

                            find . -iname '*.eopkg' | while read -r __file; do
                                rm "${__file}"
                            done

                            make bump

                            cd ../

                        fi

                    done
                done
            done < <(__list_abi_provided "${1}")

        fi

    fi

}
