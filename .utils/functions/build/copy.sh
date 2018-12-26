################################################################################
#
# __recurse_copy_eopkg <package>
#
# Recursively copies the required packages to the eopkg cache to build a given
# package. This includes all build deps, and rundeps to these build deps.
#
################################################################################

__recurse_copy_eopkg() {
    source '.utils/functions/build.sh'

    __list_builddeps "${1}" | while read -r __package; do

        find "./${__package%-devel}/" -iname '*.eopkg' | grep -E "^\./${__package%-devel}/${__package}-[^-]*-[0-9]*-1-x86_64.eopkg$" | sort -n | sed '$!d' | while read -r __package_file; do
            cp "${__package_file}" /var/lib/solbuild/local/
        done

        __recurse_copy_rundep_eopkg "${__package}"

    done

}

################################################################################
#
# __recurse_copy_rundep_eopkg <package>
#
# Recursively copies the required rundeps for a packages to the eopkg cache.
#
################################################################################

__recurse_copy_rundep_eopkg() {

    __list_rundeps "${1}" | while read -r __run_package; do

        find "./${__run_package%-devel}/" -iname '*.eopkg' | grep -E "^\./${__run_package%-devel}/${__run_package}-[^-]*-[0-9]*-1-x86_64.eopkg$" | sort -n | sed '$!d' | while read -r __package_file; do
            cp "${__package_file}" /var/lib/solbuild/local/
        done

        __recurse_copy_rundep_eopkg "${__run_package}"

    done

}
