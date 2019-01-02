################################################################################
#
# __uninstall
#
# Uninstalls all deepin packages.
#
################################################################################

__uninstall() {
    remove=()
    while read -r __package; do
        remove+=("${__package}")
    done < <(__list_packages_devel)
    sudo eopkg rmf "${remove[@]}"
}

################################################################################
#
# __install <Packge1> <Package2> ...
#
# Installs given deepin packages.
#
################################################################################

__install() {
    source '.utils/functions/build.sh'

    __install_list=()

    while read -r __package; do
        __install_list+=("$(find "./${__package%-devel}/" -iname '*.eopkg' | grep -E "^\./${__package%-devel}/${__package}-[^-]*-[0-9]*-1-x86_64.eopkg$" | sort -n | sed '$!d')")
    done < <(
        until [ "${#}" = '0' ]; do
            if ! __check_is_package "${1}"; then
                echo "Package '${1}' does not exist." >&2
            elif __check_rundeps_built "${1}" && __check_built "${1}"; then
                __list_rundeps_recurse "${1}"
            else
                echo "Package '${1}' cannot be installed due to missing rundeps." >&2
            fi
            shift
        done | __uuniq
    )

    eopkg -y install "${__install_list[@]}"

}
