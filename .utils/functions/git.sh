################################################################################
# __upgrade [package] [version]
#
# Commits an upgrade to a given package with a given version.
#
################################################################################

__upgrade() {
    __package="${1}"
    __version="${2}"
    git add "${__package}/"
    git commit -m "${__package}: Upgrade to ${__version}"
}

################################################################################
# __rebuild [package]
#
# Commits a bump and rebuild to a given package.
#
################################################################################

__rebuild() {
    __package="${1}"
    git add "${__package}/"
    git commit -m "${__package}: Bump and rebuild."
}
