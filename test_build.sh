#!/bin/bash

# Important - If any eopkg files are found, they are assumed to be correct.
# As such, if a package has been modified, be sure to remove all of its eopkg
# files before continuing with builds.

# Also, since this runs as root to avoid permission questions when unattended,
# make sure you have your packager information in your root dir.

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

__list_rundeps () {
grep -E "^${1} " 'run_deps' | sed -e 's#-devel$##' -e 's#-devel ##' -e 's/.* //'
}

__list_builddeps () {
grep -E "^${1} " 'build_deps' | sed -e 's#-devel$##' -e 's#-devel ##' -e 's/.* //'
}

__check_built () {
    if [ -z "$(find "./${1}/" -iname '*.eopkg')" ]; then
        return 1
    fi
    return 0
}

__copy_to_cache () {
echo "Copying '${1}' to cache."
cd "${1}"
cp *.eopkg /var/lib/solbuild/local/
cd ../
}

__recurse_copy_rundeps () {
__list_rundeps "${1}" | while read -r __package; do
    
    __copy_to_cache "${__package}"
    
    __recurse_copy_rundeps "${__package}"
    
done
}

__setup () {

echo 'Cleaning cache.'
rm -f /var/lib/solbuild/local/*.eopkg

__list_builddeps "${1}" | while read -r __package; do
    
    if __check_built "${1}"; then
        echo "Package '${__package}' already built."
    else
        __build "${__package}" || exit 1
    fi
    
    __list_rundeps "${__package}" | while read -r __package_; do
        
        __build "${__package_}" || exit 1
        
    done
    
done || exit 1

__list_builddeps "${1}" | while read -r __package; do

    __copy_to_cache "${__package}"

    __recurse_copy_rundeps "${__package}"
    
done || exit 1

}

__build () {

__setup "${1}" || exit 1

if __check_built "${1}"; then
    echo "Package '${1}' already built."
else
    
    echo "Building package '${1}'"
    
    cd "${1}"
    
    make local || {
        echo "Building '${1}' failed, exiting."
        exit 1
    }
    
    cd ../
    
fi

chown "${real_user}:${real_user}" ./*

}

rm -f /var/lib/solbuild/local/*.eopkg

until [ "${#}" = '0' ]; do

    __build "${1}" || exit 1
    
    shift
    
done || exit 1

exit