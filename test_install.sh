#!/bin/bash

set -e

__uninstall () {
remove=()
while read -r __package; do
    remove+=("${__package}")
done < <(tsort run_deps)
sudo eopkg rmf "${remove[@]}"
}

if [ "${1}" = '-u' ]; then
    __uninstall
    exit
fi

uuniq () {
    awk '!x[$0]++'
}

__recurse () {
    local __deps="$(sort < 'run_deps' | uniq | grep -E "^${1} ")"
    if ! [ -z "${__deps}" ]; then
        while read -r __line; do
            local __parent="${__line/ *}"
            local __child="${__line/* }"
            __recurse "${__child}"
            echo "${__line}"
        done <<< "${__deps}"
    fi | sort | uniq
}

__install () {
install=()
while read -r __package; do
    if [ -z "${__package}" ]; then
        dont_install='1'
    fi
    install+=("${__package}")
done < <(
    (
    until [ "${#}" = '0' ]; do
        __recurse "${1}" | tsort | tac
        echo "${1}"
        shift
    done
    ) | uuniq | while read -r __dir; do
        if ! [ -d "${__dir}" ]; then
            echo
            echo "${__dir} does not exist" >&2
        else
            cd "${__dir}"
            local __package="$(find . | grep -E "./${__dir}-[0-9]+.*\.eopkg$" | sort -g | tail -n 1 | sed "s#^\./#./${__dir}/#")"
            if [ -z "${__package}" ]; then
                echo 
                echo  "${__dir} is missing" >&2
            else
                echo "${__package}"
            fi
            cd ../
        fi
    done
    )

if ! [ "${dont_install}" = '1' ]; then
    sudo eopkg it "${install[@]}" -y || (
    echo '
Install failed, stepping through one at a time.'
    for __package in "${install[@]}"; do
        echo "${__package}"
        sudo eopkg it "${__package}" -y
    done
    )
fi
}

__uninstall

__install "${@}"

exit