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

    set -x

    __install_list=()
    while read -r __package; do
        if [ -z "${__package}" ]; then
            dont_install='1'
        fi
        __install_list+=("${__package}")
    done < <(
        (
            until [ "${#}" = '0' ]; do
                __list_rundeps_recurse "${1}"
                shift
            done
        ) | __uuniq | while read -r __name; do
            __dir="${__name%-devel}"
            if ! [ -d "${__dir}" ]; then
                echo
                echo "${__dir} does not exist" >&2
            else
                cd "${__dir}"
                local __package="$(find . | grep -E "./${__name}-[0-9]+.*\.eopkg$" | sort -g | tail -n 1 | sed "s#^\./#./${__dir}/#")"
                if [ -z "${__package}" ]; then
                    echo
                    echo "${__name} is missing" >&2
                else
                    echo "${__package}"
                fi
                cd ../
            fi
        done
    )

    if ! [ "${dont_install}" = '1' ]; then
        eopkg it "${__install_list[@]}" -y || (
            echo '
Install failed, stepping through one at a time.'
            for __package in "${__install_list[@]}"; do
                echo "${__package}"
                eopkg it "${__package}" -y
            done
        )
    fi
}
