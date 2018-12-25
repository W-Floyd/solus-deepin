################################################################################
#
# [...] | __color_pipe [--bold] [--underline] [--intense] <color>
#
# Colors a piped input, optionally making it bold, underlined, intense, or bold
# and intense.
#
# Valid colors are:
#   Black
#   Red
#   Green
#   Yellow
#   Blue
#   Purple
#   Cyan
#   White
#
################################################################################

__color_pipe() {

    __bold='0'
    __underline='0'
    __intense='0'
    until [ "${#}" = '0' ]; do
        if [[ "${1}" == '--'* ]]; then
            if [ "${1}" = '--bold' ]; then
                __bold='1'
                __underline='0'
            elif [ "${1}" = '--underline' ]; then
                __underline='1'
                __bold='0'
                __intense='0'
            elif [ "${1}" = '--intense' ]; then
                __intense='1'
                __underline='0'
            else
                echo "Unrecognized option '${1}'"
                exit 1
            fi
        else
            __color="${1}"
        fi
        shift
    done

    __var="${__color^}"

    if [ "${__intense}" = '1' ]; then
        __var="I${__var}"
    fi

    if [ "${__bold}" = '1' ]; then
        __var="B${__var}"
    fi

    if [ "${__underline}" = '1' ]; then
        __var="U${__var}"
    fi

    echo -e "${!__var}$(cat)${Color_Off}"
}
