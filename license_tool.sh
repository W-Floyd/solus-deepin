#!/bin/bash

source 'functions.sh'

lsdir | grep -v common | grep -v 'git' | grep -v '\.stfolder' | sed 's#^\./##' | while read -r __package; do
if ! ask "${__package} : $(grep -Ex '^license    : .*' "${__package}/package.yml" | sed 's/.* //')" N; then
    curl -s "https://raw.githubusercontent.com/$(grep --after-context=1 -x 'source     :' "./${__package}/package.yml" | sed -e '1d' -e 's/.*git|//' -e 's/\.git.*//' -e 's/.*\.com\///')/master/debian/copyright" | less
    if ask "Change to '-or-later'?" Y; then
        sed -e 's/^\(license    : .*\)\(-or-later\|-only\)/\1/' -e 's/^\(license    : .*\)/\1-or-later/' -i "./${__package}/package.yml"
    elif ask "Change to '-only'?" Y; then
        echo '2'
        sed -e 's/^\(license    : .*\)\(-or-later\|-only\)/\1/' -e 's/^\(license    : .*\)/\1-only/' -i "./${__package}/package.yml"
    elif ask "Change manually?" Y; then
        gedit "./${__package}/package.yml"
    else
        echo "Fix '${__package}' yourself then..."
    fi
    echo
else
    echo
fi
done

exit