################################################################################
# __list
#
# List all packages that have been built but changes are yet to be commited
#
################################################################################

__list() {
    find . -iname '*.eopkg' | sed -e 's#^\./##' -e 's#/.*##' | sort | uniq | grep -Fxf <(git status --short | sed -e 's#^ M ##' -e 's#/.*##' | sort | uniq)
}
