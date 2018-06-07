#!/bin/bash

if [ "${1}" = '--self' ]; then
    shift
    until [ "${#}" = '0' ]; do
        __package="${1}"
        echo -n "${__package}"
        cd "${__package}"
        if [ -z "$(git diff . | grep -E '^[+|-]' | sed 's/^.//' | grep -E '^release')" ]; then
            make bump &> /dev/null
            echo
        else
            echo ', already bumped.'
        fi
        rm -f *.eopkg
        cd ../
        shift
    done 
    exit
fi

source 'functions.sh'

__recurse () {
__list_run_deps_rev "${1}" | while read -r __line; do
    local __dependant="${__line/ *}"
    local __dependancy="${__line/* }"
    
    __recurse "${__dependant}"
    
    __list_build_deps_rev "${__dependant}" | while read -r __line; do
        local __dependant="${__line/ *}"
        local __dependancy="${__line/* }"
        
        __recurse "${__dependant}"
        echo "${__line}"
    done
done
__list_build_deps_rev "${1}" | while read -r __line; do
    local __dependant="${__line/ *}"
    local __dependancy="${__line/* }"
    
    __recurse "${__dependant}"
    echo "${__line}"
done
}

until [ "${#}" = '0' ]; do
    __recurse "${1}" | sort | uniq | tsort | tac | sed '1d' | while read -r __package; do
        echo -n "${__package}"
        cd "${__package}"
        if [ -z "$(git diff . | grep -E '^[+|-]' | sed 's/^.//' | grep -E '^release')" ]; then
            make bump &> /dev/null
            echo
        else
            echo ', already bumped.'
        fi
        rm -f *.eopkg
        cd ../
    done
    shift
done

exit
