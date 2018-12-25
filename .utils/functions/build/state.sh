################################################################################
#
# __list_tree <package>
#
# Lists all known packages related to a given package.
#
################################################################################

__list_tree() {

    if [ -e ".tmp/listed/${1}" ]; then
        return 0
    fi

    if ! [ -d '.tmp/listed/' ]; then
        mkdir '.tmp/listed/'
    fi

    touch ".tmp/listed/${1}"

    echo "${1}"

    {
        __list_builddeps "${1}"
        __list_rundeps "${1}"
    } | __uuniq | while read -r __package; do

        __list_tree "${__package}"

    done | __uuniq

}

################################################################################
#
# __check_state <package>
#
# Checks the state of all run/builddeps known for a package. This need only be
# run once, at the begining of the script. State should from then on be updated
# internally, as this is costly to run often
#
################################################################################

__check_state() {

    source '.utils/functions/build/check.sh'

    __list_tree "${1}" | while read -r __package; do
        __check_built "${__package}"
        __rundeps_store "${__package}"
    done

    rm -r '.tmp/listed/'

}