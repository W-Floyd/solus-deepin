################################################################################
#
# __tsort_prepare_builddeps
#
# Takes all known builddeps and spits out a tsortable list of packages.
#
################################################################################

__tsort_prepare_builddeps() {
    find '.tmp/builddeps/' -type f | sed '/^$/d' | while read -r __file; do
        __package="${__file/*\//}"
        
        if ! __check_failed "${__package}"; then

            if [ -e ".rundeps/${__package}" ]; then
                while read -r __line; do
                    echo "${__package} ${__line}"
                done < ".rundeps/${__package}"
            fi
            while read -r __line; do
                echo "${__package} ${__line}"
            done < "${__file}"

        fi
    done
}

################################################################################
#
# __tsort_prepare
#
# Takes all known rdeps and spits out a tsortable list of packages.
#
################################################################################

__tsort_prepare() {
    {
        __tsort_prepare_builddeps
    } | sort | uniq
}
