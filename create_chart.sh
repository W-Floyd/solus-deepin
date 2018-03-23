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

{

echo 'digraph {
    overlap=false
    center=true
    splines=true
    sep="0.1"
    node [style=filled, shape=record, color="black" fillcolor="none" ]
'

while read -r __type; do
    while read -r __line; do
        __parent="${__line/ *}"
        __child="${__line/* }"
        echo "    \"${__parent}\" -> \"${__child}\"[${__type}];"
    done < "${__type}_deps"
done <<< 'run
build'

echo '}'

} > graph.dot

sed -e 's/\[run\]/[color=blue]/' \
-e 's/\[done\]/\[fillcolor=darkolivegreen1\]/' \
-e 's/\[build\]/\[color=red\]/' \
-e 's/\[modified\]/\[fillcolor=orange\]/' \
-e 's/\[new\]/\[fillcolor=limegreen\]/' \
-e 's/\[error\]/\[fillcolor=tomato\]/' graph.dot | neato -Ln5 -Tgtk

exit
