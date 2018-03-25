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

uuniq () {
    awk '!x[$0]++'
}

__list_rundeps () {
grep -E "^${1} " 'run_deps' | sed -e 's#-devel$##' -e 's#-devel ##'
}

__list_builddeps () {
grep -E "^${1} " 'build_deps' | sed -e 's#-devel$##' -e 's#-devel ##'
}

__check_built () {
    if [ -z "$(find "./${1}/" -iname '*.eopkg')" ]; then
        return 1
    fi
    return 0
}

__copy_to_cache () {
cd "${1}"
cp *.eopkg /var/lib/solbuild/local/
cd ../
}

__recurse_rundep_copy () {

    __internal () {
        __list_rundeps "${1}" | while read -r __line_; do
            local __dependant_="${__line_/ *}"
            local __dependancy_="${__line_/* }"
            __internal "${__dependancy_}"
            __copy_to_cache "${__dependancy_}"
        done || exit 1
    }
    
    __list_builddeps "${1}" | while read -r __line; do
        local __dependant="${__line/ *}"
        local __dependancy="${__line/* }"
        __internal "${__dependancy}"
        __copy_to_cache "${__dependancy}"
    done

}

__recurse () {
__list_builddeps "${1}" | while read -r __line; do
    local __dependant="${__line/ *}"
    local __dependancy="${__line/* }"
    
    __build "${__dependancy}" || exit 1
    __copy_to_cache "${__dependancy}"
    
    __list_rundeps "${__dependancy}" | while read -r __line_; do
        local __dependant_="${__line_/ *}"
        local __dependancy_="${__line_/* }"
        __build "${__dependancy_}" || exit 1
        __copy_to_cache "${__dependancy_}"
    done || exit 1
    
done || exit 1
}

__build () {

if __check_built "${1}"; then
    echo "Package '${1}' already built."
else

    __recurse "${1}"
    
    __recurse_rundep_copy "${1}"
    
    echo "Building package '${1}'"
    
    cd "${1}"
    
    make local || {
        echo "Building '${1}' failed, exiting."
        exit 1
    }
    
    cd ../
    
fi

rm -f /var/lib/solbuild/local/*.eopkg

}

rm -f /var/lib/solbuild/local/*.eopkg

until [ "${#}" = '0' ]; do

    __build "${1}"
    
    shift
    
done

exit
