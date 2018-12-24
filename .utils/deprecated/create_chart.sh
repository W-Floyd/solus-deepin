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

touch 'checklist'

__check_done () {

    grep -x "${1}" -q < 'checklist' || return 1
    
    return 0

}

__recurse () {

if __check_done "${1}"; then
    return
fi

echo "${1}" >> 'checklist'

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

git diff-index --name-only HEAD -- | grep -E "^${1}/" -q && echo "    \"${1}\"[modified];"

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
    
        if [ "${1}" = '-m' ]; then
        
            git diff-index --name-only HEAD -- | grep '/' | sed 's#/.*##' | sort | uniq | while read -r __package; do
            
                __recurse "${__package}"
                
            done
            
        else

            __recurse "${1}"

            echo "    \"${1}\"[select];"
            
        fi

        shift

    done

fi

}| sort > "${__tmpfile}"

cp "${__tmpfile}" "${__tmpfile2}"

grep ' -> ' < "${__tmpfile}" | sed 's#\[.*##' | uniq -d | while read -r __line; do
    sed -e "s#^    ${__line}\[.*##" -i "${__tmpfile2}"
    echo "    ${__line}[run_build];" >> "${__tmpfile2}"
done

grep -v ' -> ' < "${__tmpfile}" | sed 's#\[.*##' | uniq -d | while read -r __line; do
    sed -e "s#^    ${__line}\[.*##" -i "${__tmpfile2}"
    echo "    ${__line}[select_modified];" >> "${__tmpfile2}"
done

sed -e '/^$/d' -i "${__tmpfile2}"

{

echo 'digraph {
    overlap=false
    center=true
    splines=true
    sep="0.05"
    node [style=filled, shape=record, color="black" fillcolor="none" ]
'

sort "${__tmpfile2}"

echo '}'

} > graph.dot

rm "${__tmpfile}" "${__tmpfile2}" 'checklist'

sed -e 's/\[run\]/[color=blue]/' \
-e 's/\[done\]/\[fillcolor=darkolivegreen1\]/' \
-e 's/\[build\]/\[color=red\]/' \
-e 's/\[run_build\]/\[color="red:blue"\]/' \
-e 's/\[modified\]/\[fillcolor=orange\]/' \
-e 's/\[new\]/\[fillcolor=limegreen\]/' \
-e 's/\[error\]/\[fillcolor=tomato\]/' \
-e 's/\[select\]/\[fillcolor=seashell2\]/' \
-e 's/\[select_modified\]/\[fillcolor=darkorange2\]/' graph.dot | neato -Ln5 -Tgtk

exit
