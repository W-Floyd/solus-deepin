#!/bin/bash

source 'functions.sh'

################################################################################

__action="${1}"
shift

case ${__action} in

    git)
        __subaction="${1}"
        shift

        case ${__subaction} in

            upgrade)
                __upgrade "${1}" "${2}"
                ;;

            rebuild)
                __rebuild "${1}"
                ;;

        esac
        ;;

    list)
        __list
        ;;

esac

################################################################################

exit
