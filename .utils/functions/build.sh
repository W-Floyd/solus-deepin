################################################################################
#
# [...] | __list_builddeps_raw
#
# Wraps `__yaml2json` and `__jq`, then spits out a raw list of builddeps.
#
################################################################################

__list_builddeps_raw() {
    cat "./${1}/package.yml" | __yaml2json | __jq '.builddeps' | sed -e '1d' -e '$d' -e 's/^ *"//' -e 's/",\?$//'
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
# __list_builddeps <package>
#
# Wraps `__list_builddeps_raw` and `__interpret_builddeps`, then spits out a
# list of builddeps that come from our packages.
#
################################################################################

__list_builddeps() {
    __list_builddeps_raw "${1}" | __interpret_builddeps | sed 's/-devel$//' | grep -Fxf <(__list_packages)
}

################################################################################
#
# [...] | __list_rundeps_raw
#
# Wraps `__yaml2json` and `__jq`, then spits out a raw list of rundeps.
#
################################################################################

__list_rundeps_raw() {
    cat "./${1}/package.yml" | __yaml2json | __jq '.rundeps' | sed -e '1d' -e '$d' -e 's/^ *"//' -e 's/",\?$//'
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
# __list_rundeps_eopkg_store <package>
#
# Wraps `__list_rundeps_eopkg_raw`, then spits out a list of rundeps that come
# from our packages for all .eopkg files for the given package, storing them in
# a file to use later.
#
################################################################################

__list_rundeps_eopkg_store() {

    if [ -e ".rundeps/${1}" ]; then
        rm ".rundeps/${1}"
    fi
    find "./$(sed 's/-devel$//' <<< "${1}")/" -iname '*.eopkg' | grep -E "^\./$(sed 's/-devel$//' <<< "${1}")/${1}-[^-]*-[0-9]*-1-x86_64.eopkg$" | while read -r __package_file; do
        __list_rundeps_eopkg_raw "${__package_file}"
    done | sort | uniq | grep -Fxf <(__list_packages) > ".rundeps/${1}"

}

################################################################################
#
# __list_rundeps_eopkg <package>
#
# Wraps `__list_rundeps_eopkg_raw`, then spits out a list of rundeps that come
# from our packages for all .eopkg files for the given package.
#
################################################################################

__list_rundeps_eopkg() {

    if ! [ -e ".rundeps/${1}" ]; then
        __list_rundeps_eopkg_store "${1}"
    fi
    cat ".rundeps/${1}"

}

################################################################################
#
# __list_rundeps <package>
#
# Wraps `__list_rundeps_raw` and spits out a list of rundeps that come from
# our packages.
#
################################################################################

__list_rundeps() {
    source '.utils/functions/build/check.sh'
    if __check_built "${1}"; then
        __list_rundeps_eopkg "${1}"
    else
        __list_rundeps_raw "${1}" | sed 's/-devel$//' | grep -Fxf <(__list_packages)
    fi
}

################################################################################
#
# __build <package>
#
# Builds a given package.
#
################################################################################

__build() {

    __error='0'

    __build_deps="$(__list_builddeps "${1}")"

    cd "$(sed 's/-devel$//' <<< "${1}")"

    if [ -z "${__build_deps}" ]; then
        make &> "../.tmp/log/${1}" || {
            pushd ../ &> /dev/null
            __mark_failed "${1}"
            popd &> /dev/null
            __error='1'
        }
    else
        make local &> "../.tmp/log/${1}" || {
            pushd ../ &> /dev/null
            __mark_failed "${1}"
            popd &> /dev/null
            __error='1'
        }
    fi

    cd ../

    if [ "${__error}" = '1' ]; then
        return 1
    fi
}

################################################################################
#
# __build_sub_loop <package> <symbol>
#
# A sub function so that formatting may be done on output
#
################################################################################

__build_sub_loop() {

    source '.utils/functions/color.sh'
    source '.utils/functions/build/check.sh'
    source '.utils/variables/build_symbols.sh'

    __package="${1}"
    __outer_symbol="__symbol_${3}_${2}"
    __outer_symbol="${!__outer_symbol}"

    __symbol_horizontal="__symbol_${3}_horizontal"
    __symbol_arrow="__symbol_${3}_arrow"
    __symbol_vertical="__symbol_${3}_vertical"

    __symbol_horizontal="${!__symbol_horizontal}"
    __symbol_arrow="${!__symbol_arrow}"
    __symbol_vertical="${!__symbol_vertical}"

    echo -n "${!__outer_symbol}${!__symbol_horizontal}${!__symbol_arrow} "

    if ! [ -d '.tmp/log/' ]; then
        mkdir '.tmp/log/'
    fi

    if __check_ready_to_build "${__package}"; then
        {
            nohup '.utils/subutils/build/real_build.sh' "${__package}" &
        } &> /dev/null

    fi

    __check_deps "${__package}"

    if __check_failed "${__package}"; then
        __color='red'
    elif __check_built "${__package}"; then
        __color='green'
    elif __check_building "${__package}"; then
        __color='yellow'
    else
        __color='blue'
    fi

    echo "${__package}" | __color_pipe --bold "${__color}" | {
        if __check_building "${__package}"; then
            sed "s#\$#  $(echo '[BUILDING]' | __color_pipe --underline yellow)#"
        #elif __check_built "${__package}"; then
        #    sed "s#\$#  $(echo '[BUILT]' | __color_pipe --underline green)#"
        #elif __check_failed "${__package}"; then
        #    sed "s#\$#  $(echo '[FAILED]' | __color_pipe --underline red)#"
        else
            cat
        fi
    }

    __mark_displayed "${__package}"

    if ! __check_built "${__package}" || ! __check_rundeps_built "${__package}"; then

        __list="$(__build_loop "${__package}")"
        if ! [ -z "${__list}" ]; then
            echo "${__list}" | sed "s/^/${!__symbol_vertical}   /"
        fi

    fi

}

################################################################################
#
# __build_loop <package>
#
# Iterates through and draws a tree of build steps
#
################################################################################

__build_loop() {

    source '.utils/variables/build_symbols.sh'

    __sub() {
        while read -r __package; do

            if ! __check_displayed "${__package}"; then
                echo "${__package}"
            fi

        done <<< "${1}"
    }

    __raw_list="$(__list_builddeps "${1}")"

    __list="$(__sub "${__raw_list}")"

    echo "${__list}" | sed '/^$/d' | sed '$d' | while read -r __package; do

        __build_sub_loop "${__package}" list build

    done

    echo "${__list}" | sed '/^$/d' | sed '$!d' | while read -r __package; do

        __build_sub_loop "${__package}" end build

    done

    __raw_list="$(__list_rundeps "${1}")"

    __list="$(__sub "${__raw_list}")"

    echo "${__list}" | sed '/^$/d' | sed '$d' | while read -r __package; do
        __build_sub_loop "${__package}" list run
    done

    echo "${__list}" | sed '/^$/d' | sed '$!d' | while read -r __package; do
        __build_sub_loop "${__package}" end run
    done
}

################################################################################
#
# __build_entry <package>
#
# Enters into a build loop.
#
################################################################################

__build_entry() {

    source '.utils/variables/build_symbols.sh'

    echo "${1}" | while read -r __package; do
        __build_sub_loop "${__package}" list build
    done | sed -r 's/^.{4}//'

}
