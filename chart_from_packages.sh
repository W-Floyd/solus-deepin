#!/bin/bash

max_depth='0'

list_direct='1'

until [ "${#}" = '0' ]; do
    export "${1}"
done

source 'functions.sh'

__temp_dir="$(mktemp -d)"

__strip_name () {
cat | sed -e  's/-devel$//' -e 's/-docs$//'
}

__mark_done () {
touch "${__temp_dir}/${1}"
}

__check_done () {
if [ -e "${__temp_dir}/${1}" ]; then
    return 0
fi
return 1
}

__check_real () {
if [ -d "$(__strip_name <<< "${1}")" ]; then
    return 0
fi
return 1
}

__find_newest () {
declare -a __packages __releases
declare -A __latest_release

__stripped_name="$(__strip_name <<< "${1}")"

__package_list="$(find "${__stripped_name}" -iname '*.eopkg' | sort | sed -e 's#.*/##' -e '/^$/d')"

if [ -z "${__package_list}" ]; then
    return 1
fi

while read -r __package; do
    __packages+=("${__package}")
done < <(sed -e 's#-[^-]*-[0-9]*-1-x86_64\.eopkg##' <<< "${__package_list}")

while read -r __release; do
    __releases+=("${__release}")
done < <(sed -e 's#-1-x86_64\.eopkg##' -e 's#.*-##' <<< "${__package_list}")


for index in "${!__packages[@]}"; do
    __package="${__packages[index]}"
    __release="${__releases[index]}"
    if [ ${__latest_release[${__package}]+exists} ]; then
        if [ "${__latest_release[${__package}]}" -lt "${__release}" ]; then
            __latest_release[${__package}]="${__release}"
        fi
    else
        __latest_release[${__package}]="${__release}"
    fi
done

echo "./${__stripped_name}/$(grep -E "^${1}-[^-]*-[0-9]*-1-x86_64.eopkg$" <<< "${__package_list}")"

}

# __recurse <package> <current_depth>

__recurse () {

local __base_name __real_name __info_search __current_depth __package

__base_name="$(sed 's#^\./\([^/]*\)/.*#\1#' <<< "${1}")"

__real_name="$(sed -e 's#.*/##' -e 's#-[^-]*-[0-9]*-1-x86_64\.eopkg##' <<< "${1}")"

if __check_real "${__base_name}"; then
    echo "    \"${__real_name}\"[new];"
    __info_search="$(__find_newest "${__real_name}")"
else
    __info_search="${1}"
fi

if ! [ -z "${2}" ]; then
    __current_depth="${2}"
else
    __current_depth='0'
fi

if ! __check_done "${__real_name}" && ! [ -z "${__info_search}" ]; then

    echo "    \"${__real_name}\""

    xmllint <(eopkg info "${__info_search}" --xml) --xpath 'string(//PISI/Package/RuntimeDependencies)' | sed -e 's/^ *//' -e '/^$/d' | while read -r __package; do
        if ( __check_real "${__package}" ) || [ "${max_depth}" -gt "${__current_depth}" ]; then
            __recurse "${__package}" "$((__current_depth+1))"
            echo "    \"${__real_name}\" -> \"${__package}\"[run];"
        elif [ "${list_direct}" = '1' ]; then
            echo "    \"${__real_name}\" -> \"${__package}\"[run];"
        fi
    done
        
fi

__mark_done "${__real_name}"

}


{

echo 'digraph {
    overlap=false
    center=true
    splines=true
    sep="0.1"
    node [style=filled, shape=record, color="black" fillcolor="none" ]
'

{

while read -r __file; do
    __recurse "${__file}"
done < <(find . -iname '*.eopkg')

} | sort | uniq | sed -e '/^$/d'

echo '}'

} > graph.dot

sed -e 's/\[run\]/[color=blue]/' \
-e 's/\[done\]/\[fillcolor=darkolivegreen1\]/' \
-e 's/\[build\]/\[color=red\]/' \
-e 's/\[run_build\]/\[color="red:blue"\]/' \
-e 's/\[modified\]/\[fillcolor=orange\]/' \
-e 's/\[new\]/\[fillcolor=limegreen\]/' \
-e 's/\[error\]/\[fillcolor=tomato\]/' \
-e 's/\[select\]/\[fillcolor=seashell2\]/' \
-e 's/\[select_modified\]/\[fillcolor=darkorange2\]/' graph.dot | neato -Ln5 -Tgtk

rm -r "${__temp_dir}"

exit
