#!/bin/bash

uuniq () {
    awk '!x[$0]++'
}

__list_rundeps () {
sort < 'run_deps' | uniq | grep -E " ${1}$"
}

__list_builddeps () {
sort < 'build_deps' | uniq | grep -E " ${1}$"
}

__recurse () {
__list_rundeps "${1}" | while read -r __line; do
    local __dependant="${__line/ *}"
    local __dependancy="${__line/* }"
    
    __recurse "${__dependant}"
    
    __list_builddeps "${__dependant}" | while read -r __line; do
        local __dependant="${__line/ *}"
        local __dependancy="${__line/* }"
        
        __recurse "${__dependant}"
        echo "${__line}"
    done
done
__list_builddeps "${1}" | while read -r __line; do
    local __dependant="${__line/ *}"
    local __dependancy="${__line/* }"
    
    __recurse "${__dependant}"
    echo "${__line}"
done
}

__recurse "${1}" | sort | uniq | tsort | tac | sed '1d' | while read -r __package; do
    echo "${__package}"
    #cd "${__package}" && make bump &> /dev/null && cd ../
done

exit
