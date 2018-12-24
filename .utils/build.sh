#!/bin/bash

source '.utils/functions.sh'
source '.utils/functions/build.sh'

mkdir -p '.rundeps'
mkdir -p '.tmp/log'
mkdir -p '.tmp/rundeps'
mkdir -p '.tmp/displayed'

tput clear

__draw() {
    echo "${1}" > '.tmp/output'
    __build_entry "${1}" > '.tmp/output'
    tput clear
    tput cup 0 0
    cat '.tmp/output'
}

__draw "${1}"

while true; do

    __old_hash="$(__hash_dir './.tmp/')"
    __new_hash="${__old_hash}"

    __wait='0'

    while [ "${__wait}" -lt 5 ]; do
        sleep 0.2s
        __old_hash="${__new_hash}"
        __new_hash="$(__hash_dir './.tmp/')"
        if ! [ "${__old_hash}" = "${__new_hash}" ] || ! [ -e './.tmp/building' ]; then
            break
        fi
        __wait=$((__wait + 1))
    done

    rm .tmp/displayed/*

    __draw "${1}"

    if ! [ -e '.dont_quit' ]; then
        break
    else
        rm '.dont_quit'
    fi
done

exit
