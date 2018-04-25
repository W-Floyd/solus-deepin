#!/bin/bash

# dframeworkdbus deepin-qt-dbus-factory
# dtkcore dtkcore
# dtkwidget dtkwidget
# geoip geoip
# libbson-1.0 libbson
# libdeepin-mutter deepin-mutter
# libmongoc-1.0 libmongoc
# libqcef libqcef
# Qt5Xdg libqtxdg

source 'functions.sh'

__recurse () {

{

__list_build_deps "${1}"

} | while read -r __line; do

    __parent="${__line/ *}"
    __child="${__line/* }"
    echo "    \"${__parent}\" -> \"${__child}\"[build];" | sed 's/-devel"/"/g'

    __recurse "${__child}"

done

{

__list_run_deps "${1}"

} | while read -r __line; do

    __parent="${__line/ *}"
    __child="${__line/* }"
    echo "    \"${__parent}\" -> \"${__child}\"[run];" | sed 's/-devel"/"/g'

    __recurse "${__child}"

done

git diff-index --name-only HEAD -- | grep -E "^${1}/" -q && echo "    ${1}[modified]"

}

__tmpfile="$(mktemp)"
__tmpfile2="$(mktemp)"
{
if [ "${#}" = '0' ]; then
    while read -r __type; do
        while read -r __line; do
            __parent="${__line/ *}"
            __child="${__line/* }"
            echo "    \"${__parent}\" -> \"${__child}\"[${__type}];" | sed 's/-devel"/"/g'
        done < "${__type}_deps"
    done <<< 'run
build'
    git diff-index --name-only HEAD -- | grep '/' | sed 's#/.*##' | sort | uniq | sed 's/\(.*\)/    "\1"[modified];/'
else

    until [ "${#}" = '0' ]; do

        __recurse "${1}"

        echo "    \"${1}\"[fillcolor="seashell2"]"

        shift

    done

fi

}| sort > "${__tmpfile}"

cp "${__tmpfile}" "${__tmpfile2}"

sed 's#\[.*##' < "${__tmpfile}" | uniq -d | while read -r __line; do
    sed -e "s#^    ${__line}\[.*##" -i "${__tmpfile2}"
    echo "    ${__line}[run_build];" >> "${__tmpfile2}"
done

sed -e '/^$/d' -i "${__tmpfile2}"

{

echo 'digraph {
    overlap=false
    center=true
    splines=true
    sep="0.1"
    node [style=filled, shape=record, color="black" fillcolor="none" ]
'

sort "${__tmpfile2}"

echo '}'

} > graph.dot

rm "${__tmpfile}" "${__tmpfile2}"

sed -e 's/\[run\]/[color=blue]/' \
-e 's/\[done\]/\[fillcolor=darkolivegreen1\]/' \
-e 's/\[build\]/\[color=red\]/' \
-e 's/\[run_build\]/\[color="red:blue"\]/' \
-e 's/\[modified\]/\[fillcolor=orange\]/' \
-e 's/\[new\]/\[fillcolor=limegreen\]/' \
-e 's/\[error\]/\[fillcolor=tomato\]/' graph.dot | neato -Ln5 -Tgtk

exit
