################################################################################
#
# __list_builddeps_raw <package>
#
# Wraps `__yaml2json` and `__jq`, then spits out a raw list of builddeps.
#
################################################################################

__list_builddeps_raw() {
    __yaml2json < "./${1%-devel}/package.yml" | __jq '.builddeps' | sed -e '1d' -e '$d' -e 's/^ *"//' -e 's/",\?$//'
}

################################################################################
#
# [...] | __interpret_builddeps
#
# Wraps `__yaml2json` and `__jq`, then spits out a cleaned up list of builddeps.
#
################################################################################

__interpret_builddeps() {
    __tmp_file="$(mktemp)"
    cat > "${__tmp_file}"
    sed \
        $(
            {
                cat pkgconfig_dictionary
                echo
            } | while read -r __line; do
                __orig="${__line/ */}"
                __new="${__line/* /}"
                printf -- -e
                printf -- ' '
                printf -- "s/^${__orig}$/${__new}/"
                printf -- ' '
            done
        ) \
        -i "${__tmp_file}"
    cat "${__tmp_file}"
    rm "${__tmp_file}"
}

################################################################################
#
# __builddeps_store <package>
#
# Wraps `__list_builddeps_raw` and `__interpret_builddeps`, then spits out a
# list of builddeps that come from our packages, storing them in a file to use
# later.
#
################################################################################

__builddeps_store() {
    __list_builddeps_raw "${1}" | __interpret_builddeps | grep -Fxf <(__list_packages_devel) > ".tmp/builddeps/${1}"
}

################################################################################
#
# __list_builddeps <package>
#
# Wraps `__builddeps_store` spits out a list of builddeps that come from our
# packages.
#
################################################################################

__list_builddeps() {

    if ! [ -d '.tmp/builddeps' ]; then
        mkdir '.tmp/builddeps'
    fi

    if ! [ -e ".tmp/builddeps/${1}" ]; then
        __builddeps_store "${1}"
    fi

    cat ".tmp/builddeps/${1}" | sed '/^$/d'

}

################################################################################
#
# [...] | __list_rundeps_raw
#
# Wraps `__yaml2json` and `__jq`, then spits out a raw list of rundeps.
#
################################################################################

__list_rundeps_raw() {
    __yaml2json < "./${1%-devel}/package.yml" | __jq '.rundeps' | sed -e '1d' -e '$d' -e 's/^ *"//' -e 's/",\?$//'
}

################################################################################
#
# __list_rundeps_eopkg_raw <file.eopkg>
#
# Wraps `__xmllint`, then spits out a raw list of rundeps.
#
################################################################################

__list_rundeps_eopkg_raw() {

    let itemsCount=$(__xmllint --xpath 'count(/PISI/Package/RuntimeDependencies/Dependency)' <(eopkg info --xml "${1}") | cat)
    declare -a __rundeps=()

    for ((i = 1; i <= $itemsCount; i++)); do
        __rundeps[$i]="$(__xmllint --xpath '/PISI/Package/RuntimeDependencies/Dependency['$i']/text()' <(eopkg info --xml "${1}") | cat)"
    done

    for __rundep in ${__rundeps[@]}; do
        echo "${__rundep}"
    done

}

################################################################################
#
# __rundeps_store <package>
#
# Wraps `__list_rundeps_eopkg_raw`, then spits out a list of rundeps that come
# from our packages, storing them in a file to use later.
#
################################################################################

__rundeps_store() {
    if [ -e ".rundeps/${1}" ]; then
        rm ".rundeps/${1}"
    fi
    touch ".rundeps/${1}"
    if ! __check_built; then
        __list_rundeps_raw "${1}" | sort | uniq | grep -Fxf <(__list_packages_devel) | sed '/^$/d' > ".rundeps/${1}"
    else
        find "./${1%-devel}/" -iname '*.eopkg' | while read -r __package_file; do
            __list_rundeps_eopkg_raw "${__package_file}" | sort | uniq | grep -Fxf <(__list_packages_devel) | sed '/^$/d' > ".rundeps/$(sed -e 's#-[^-]*-[0-9]*-1-x86_64\.eopkg$##' -e 's#.*/##' <<< "${__package_file}")"
        done
    fi
}

################################################################################
#
# __list_rundeps_eopkg <package>
#
# Wraps `__rundeps_store`, then spits out a list of rundeps that come from our
# packages for all .eopkg files for the given package.
#
################################################################################

__list_rundeps_eopkg() {

    if ! [ -e ".rundeps/${1}" ]; then
        __rundeps_store "${1}"
    fi
    cat ".rundeps/${1}"

}

################################################################################
#
# __list_rundeps <package>
#
# Wraps `__list_rundeps_raw` and `__list_rundeps_eopkg` to spit out a list of
# rundeps that come from
# our packages.
#
################################################################################

__list_rundeps() {
    source '.utils/functions/build/check.sh'
    {
        if __check_built "${1}"; then
            __list_rundeps_eopkg "${1}"
        else
            __list_rundeps_raw "${1}" | grep -Fxf <(__list_packages_devel)
        fi
    } | sed '/^$/d'
}

################################################################################
#
# __list_rundeps_recurse <package>
#
# Wraps `__list_rundeps` and recursively finds all required rundeps for a given
# package, spitting out a list including the given package.
#
################################################################################

__list_rundeps_recurse() {

    {

        echo "${1}"

        __list_rundeps "${1}" | while read -r __package; do
            __list_rundeps_recurse "${__package}"
        done

    } | __uuniq

}

################################################################################
#
# __list_built
#
# Lists all the packages that are currently built, given an existing check of
# packages.
#
################################################################################

__list_built() {
    find '.tmp/built/' -type f | sed 's#.*/##' | sed 's/-devel$//'
}

################################################################################
#
# __list_failed
#
# Lists all the packages that are currently failed, given an existing check of
# packages.
#
################################################################################

__list_failed() {
    find '.tmp/failed/' -type f | sed 's#.*/##' | sed 's/-devel$//'
}

################################################################################
#
# __build_package <package>
#
# Builds a given package specifically.
#
################################################################################

__build_package() {

    source '.utils/functions/abi.sh'

    __error='0'

    __build_deps="$(__list_builddeps "${1}")"

    cd "${1%-devel}"

    if [ -z "${__build_deps}" ]; then
        make &> >(tee "../.tmp/log/${1}" | sed "s/^/$(tput sgr0)${1}: /" | tee -a '../.tmp/livelog' &> /dev/null) || {
            pushd ../ &> /dev/null
            __mark_failed "${1}"
            popd &> /dev/null
            __error='1'
        }
    else
        make local &> >(tee "../.tmp/log/${1}" | sed "s/^/$(tput sgr0)${1}: /" | tee -a '../.tmp/livelog' &> /dev/null) || {
            pushd ../ &> /dev/null
            __mark_failed "${1}"
            popd &> /dev/null
            __error='1'
        }
    fi

    cd ../

    __bump_abi_deps "${1}"

    if [ "${__error}" = '1' ]; then
        return 1
    fi
}

################################################################################
#
# __redraw <package> <run|build> <list|end>
#
# Redraws the package tree, given a root package.
#
################################################################################

__redraw() {

    __package_real="${1}"

    __symbol_vertical="__symbol_${2}_vertical"
    __symbol_end="__symbol_${2}_end"
    __symbol_list="__symbol_${2}_list"
    __symbol_horizontal="__symbol_${2}_horizontal"
    __symbol_arrow="__symbol_${2}_arrow"

    __symbol_vertical="${!__symbol_vertical}"
    __symbol_end="${!__symbol_end}"
    __symbol_list="${!__symbol_list}"
    __symbol_horizontal="${!__symbol_horizontal}"
    __symbol_arrow="${!__symbol_arrow}"

    __symbol_outer="__symbol_${3}"
    __symbol_outer="${!__symbol_outer}"

    __mark_displayed "${__package_real}"

    if __check_building "${__package_real}"; then
        __message='[BUILDING]'
        __color='yellow'
    elif __check_built "${__package_real}"; then
        __message='[BUILT]'
        __color='green'
    elif __check_failed "${__package_real}"; then
        __message='[FAILED]'
        __color='red'
    else
        __message='[PENDING]'
        __color='blue'
    fi

    echo -n "${__symbol_outer}${__symbol_horizontal}${__symbol_arrow} "

    echo "${__package_real}" | __color_pipe --bold "${__color}" | sed "s#\$#  $(echo "${__message}" | __color_pipe --underline "${__color}")#"

    if [ "${3}" = 'list' ]; then
        __symbol_child_outer="${__symbol_vertical}"
    else
        __symbol_child_outer=' '
    fi

    __sub() {
        __var="$(
            echo "${1}" | sed '/^$/d' | while read -r __item; do
                if ! __check_displayed "${__item}"; then
                    echo "${__item}"
                    __mark_displayed "${__item}"
                fi
            done | sed '/^$/d'
        )"
        if ! [ -z "${__var}" ]; then
            {
                if [ "$(echo "${__var}" | wc -l)" = '1' ]; then
                    echo "${__var}" | while read -r __item; do
                        __redraw "${__item}" "${2}" end "${__symbol_child_outer}"
                    done
                else
                    echo "${__var}" | sed '$d' | while read -r __item; do
                        __redraw "${__item}" "${2}" list "${__symbol_child_outer}"
                    done
                    echo "${__var}" | sed '$!d' | while read -r __item; do
                        __redraw "${__item}" "${2}" end "${__symbol_child_outer}"
                    done
                fi
            } | sed "s/^/${__symbol_child_outer}   /"
        fi
    }

    __list="$(__list_builddeps "${__package_real}")"

    __list2="$(__list_rundeps "${__package_real}")"

    __sub "${__list}" build "${3}"
    __sub "${__list2}" run "${3}"

}
