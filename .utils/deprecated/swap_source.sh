#!/bin/bash

case "${1}" in
    original)
        __source_swap () {
            sed -e "s#${__mirror}#${__original}#" -i "${__dir}/package.yml"
        }
        ;;
    mirror)
        __source_swap () {
            sed -e "s#${__original}#${__mirror}#" -i "${__dir}/package.yml"
        }
        ;;
    *)
        echo "Unknown source type '${1}'"
        echo "Use either 'original' or 'mirror'"
        exit 1
        ;;
esac

while read -r __line; do
    __dir="$(sed 's/^\([^ ]*\) *\([^ ]*\) *\([^ ]*\)$/\1/' <<< "${__line}")"
    __original="$(sed 's/^\([^ ]*\) *\([^ ]*\) *\([^ ]*\)$/\2/' <<< "${__line}")"
    __mirror="$(sed 's/^\([^ ]*\) *\([^ ]*\) *\([^ ]*\)$/\3/' <<< "${__line}")"
    __source_swap
done < 'source_list'

exit
