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
sort < 'run_deps' | uniq | grep -E "^${1} " | sed 's#-devel$##'
}

__list_builddeps () {
sort < 'build_deps' | uniq | grep -E "^${1} " | sed 's#-devel$##'
}

__recurse () {
sleep 0.1s
__list_builddeps "${1}" | while read -r __line; do
    local __dependant="${__line/ *}"
    local __dependancy="${__line/* }"
    
    __recurse "${__dependancy}"
    
    __list_rundeps "${__dependant}" | while read -r __line; do
        local __dependant="${__line/ *}"
        local __dependancy="${__line/* }"
        
        __recurse "${__dependancy}"
        echo "${__line}"
    done
done
}

__build () {
__recurse "${1}"
}

rm -f /var/lib/solbuild/local/*.eopkg

__recurse "${1}" | sort | uniq | tsort | tac | while read -r __package; do
    cd "${__package}"
    
    if [ -z "$(find . -iname '*.eopkg')" ]; then
        echo "Building '${__package}'"
        make local || {
            echo "Building '${__package}' failed, exiting."
            exit 1
        }
        echo "Built '${__package}'"
    else
        echo "Package '${__package}' already built."
    fi
    
    cp *.eopkg /var/lib/solbuild/local/
    cd ../
done

exit
