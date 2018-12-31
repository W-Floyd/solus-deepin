#!/bin/bash

# Since this runs as root by default to avoid permission questions when
# unattended, make sure you have your packager information in your root dir.

__no_root='0'

__delete_force='0'

while [[ "${1}" == '--'* ]]; do

    if [ "${1}" = '--no-root' ]; then
        __no_root='1'
    elif [ "${1}" = '--force-delete' ]; then
        __delete_force='1'
    else
        echo "Unrecognized option '${1}'"
        exit 1
    fi
    
    shift

done || exit 1
    
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

source 'functions.sh'

__tmp_dir="$(mktemp -d)"

__mark_checked () {
touch "${__tmp_dir}/$(sed 's/-devel$//' <<< "${1}")"
}

__check_built () {

    __mark_checked "${1}"

    if [ -z "$(find "./$(sed 's/-devel$//' <<< "${1}")/" -iname '*.eopkg')" ]; then
        return 1
    fi

    __current_build="$(find "./$(sed 's/-devel$//' <<< "${1}")/" -iname '*.eopkg' | sed 's#.*-\([0-9]*\)-1-x86_64\.eopkg$#\1#' | sort | uniq)"
    __target_build="$(grep -Ex '^release    : .*' "${1}/package.yml" | sed 's/.* //')"

    if ! [ "${__current_build}" = "${__target_build}" ]; then
        __quiet_remove_eopkg "./$(sed 's/-devel$//' <<< "${1}")/"
        return 1
    fi

    return 0
}

__check_checked () {
    if [ -e "${__tmp_dir}/$(sed 's/-devel$//' <<< "${1}")" ]; then
        return 0
    fi
    return 1
}

__copy_to_cache () {
echo "Copying '${1}' to cache."
if __check_built "${1}"; then
    cd "$(sed 's/-devel$//' <<< "${1}")"
    cp *.eopkg /var/lib/solbuild/local/
    cd ../
else
    echo "Package '${1}' not built!"
    exit 1
fi
}

__recurse_copy_rundeps () {
__list_run_deps --true "${1}" | sed 's/.* //' | while read -r __package; do
    
    __copy_to_cache "${__package}" || exit 1
    
    __recurse_copy_rundeps "${__package}" || exit 1
    
done
}

__recurse_build_rundeps_sub () {
__list_run_deps --true "${1}" | sed 's/.* //' | while read -r __package; do
    
    echo "${__package}"
    
    __recurse_build_rundeps_sub "${__package}" || exit 1
    
done
}

__recurse_build_rundeps () {
__recurse_build_rundeps_sub "${1}" | while read -r __package; do
    if ! __check_checked "${__package}"; then
        
        if __check_built "${__package}"; then
            echo "Package '${__package}' already built."
        else
            __build "${__package}" || exit 1
        fi
        
    fi || exit 1
done
}

__quiet_remove_eopkg () {
rm -f "${1}/"*.eopkg &> /dev/null
}

__setup () {

echo 'Cleaning cache.'
__quiet_remove_eopkg /var/lib/solbuild/local

__recurse_build_rundeps "${1}" || exit 1

__list_build_deps "${1}" | sed 's/.* //' | while read -r __package; do
    
    if ! __check_checked "${__package}"; then
    
        if __check_built "${__package}"; then
            echo "Package '${__package}' already built."
        else
            __build "${__package}" || exit 1
        fi
    
    fi || exit 1
    
    __list_run_deps --true "${__package}" | sed 's/.* //' | while read -r __package_; do
        
        if ! __check_checked "${__package_}"; then
            
            if __check_built "${__package_}"; then
                echo "Package '${__package_}' already built."
            else
                __build "${__package_}" || exit 1
            fi
            
        fi || exit 1
        
    done
    
done || exit 1

__list_build_deps "${1}" | sed 's/.* //' | while read -r __package; do

    __copy_to_cache "${__package}" || exit 1

    __recurse_copy_rundeps "${__package}" || exit 1
    
done || exit 1

}

__build () {

__setup "${1}" || exit 1

if __check_built "${1}"; then
    echo "Package '${1}' already built."
else
    
    echo "Building package '$(sed 's/-devel$//' <<< "${1}")'"
    
    __build_deps="$(__list_build_deps "${1}")"
    
    cd "$(sed 's/-devel$//' <<< "${1}")"
    
    __sub_exit () {
        echo "Building '${1}' failed, exiting."
    }
    
    {
    if [ -z "${__build_deps}" ]; then
        make || { __sub_exit "${1}"; exit 1; }
    else
        make local || { __sub_exit "${1}"; exit 1; }
    fi
    }
    
    cd ../
    
fi || exit 1

chown "${real_user}:${real_user}" -R .

}

__quiet_remove_eopkg /var/lib/solbuild/local

if [ "${__delete_force}" = '1' ]; then
    for __input in "${@}"; do
        __quiet_remove_eopkg "${__input}"
    done
fi

if [ "${#}" = '0' ]; then

    __list_packages | while read -r __package; do

        if __check_built "${__package}"; then
            echo "Package '${__package}' already built."
        else
            __build "${__package}" || exit 1
        fi

    done

else

    until [ "${#}" = '0' ]; do

        __build "${1}" || exit 1
        
        shift
        
    done || exit 1

fi

rm -r "${__tmp_dir}"

exit
