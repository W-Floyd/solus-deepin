#!/bin/bash

__ignore='common
.git'

__new="$(git status --porcelain --untracked-files=all | grep -E '^\?\?' | grep -E '/' | sed -e 's/^[^ ]* //' -e 's#^\([^/]*\)/.*#\1#' | grep -Fxvf <(echo "${__ignore}"))"
__modified="$(git diff --name-only | sed 's#^\([^/]*\)/.*#\1#' | sort | uniq | grep -Fxvf <(echo "${__ignore}"))"
__done="$(find ./ -maxdepth 1 -type d | sed -e 's#^\./##' -e '/^$/d' | sort | uniq | grep -Fxvf <(echo "${__ignore}") | grep -Fxvf <(echo "${__modified}") | grep -Fxvf <(echo "${__new}"))"

__ignore_list="$(cat ignore_list)"

__pkgconfig_list='dframeworkdbus deepin-qt-dbus-factory
dtkcore dtkcore
dtkwidget dtkwidget
geoip geoip
libbson-1.0 libbson
libdeepin-mutter deepin-mutter
libmongoc-1.0 libmongoc
Qt5Xdg libqtxdg'

(

echo 'digraph {
    overlap=false
    center=true
    splines=true
    sep="0.1"
    node [style=filled, shape=record, color="black" fillcolor="none" ]
'

if ! [ -z "${__new}" ]; then
    sed 's/\(.*\)/    "\1"[new]/' <<< "${__new}"
fi
if ! [ -z "${__modified}" ]; then
    sed 's/\(.*\)/    "\1"[modified]/' <<< "${__modified}"
fi
if ! [ -z "${__done}" ]; then
    sed 's/\(.*\)/    "\1"[done]/' <<< "${__done}"
fi

(
if ! [ -z "${__new}" ]; then
    echo "${__new}"
fi
if ! [ -z "${__modified}" ]; then
    echo "${__modified}"
fi
if ! [ -z "${__done}" ]; then
    echo "${__done}"
fi
) | sort | uniq | sed '/^$/d' | while read -r __package; do
    cd "${__package}"

    if [ -e package.yml ]; then

        while read -r __search; do

            cat package.yml | pcregrep -M -o1 "${__search} *:((\n|.)*):" | pcregrep -Mv ':((\n|.)*)' | sed '/^$/d' | sed 's/^.* //' | sed 's/-devel$//' | while read -r __dep; do
                if ! grep -qx "${__dep}" <<< "${__ignore_list}"; then
                    if [[ "${__dep}" == 'pkgconfig('* ]]; then
                        __pkgconfig="$(sed "s/pkgconfig(\(.*\))/\1/" <<< "${__dep}")"
                        if grep -qE "^${__pkgconfig}" <<< "${__pkgconfig_list}"; then
                            grep -E "^${__pkgconfig}" <<< "${__pkgconfig_list}" | sed -e 's/^.* //' -e 's/-devel$//'
                        else
                            echo "${__dep}"
                        fi
                    else
                        echo "${__dep}"
                    fi

                fi | sed "s/\(.*\)/\"${__package}\" -> \"\1\"\[$(sed 's/deps$//' <<< "${__search}")\]/"
            done

        done <<< 'builddeps
rundeps'

    else
        echo "\"${__package}\"[error]"
    fi

    cd ../
done | sed 's/\(.*\)/    \1/' | sort | uniq

) > graph.dot

cp graph.dot _graph.dot

while read -r __modified_package; do
    ./dep_list.sh "${__modified_package}" -r
done <<< "${__modified}" | sed -e '/^$/d' -e 's/\(.*\)/    "\1"\[modified\]/' >> _graph.dot

mv _graph.dot graph.dot

echo '}' >> graph.dot

sed -e 's/\[run\]/[color=blue]/' \
-e 's/\[done\]/\[fillcolor=darkolivegreen1\]/' \
-e 's/\[build\]/\[color=red\]/' \
-e 's/\[modified\]/\[fillcolor=orange\]/' \
-e 's/\[new\]/\[fillcolor=limegreen\]/' \
-e 's/\[error\]/\[fillcolor=tomato\]/' graph.dot | neato -Ln5 -Tgtk

exit