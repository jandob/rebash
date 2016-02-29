#!/usr/bin/env bash
# shellcheck source=./core.sh
source $(dirname ${BASH_SOURCE[0]})/core.sh

array_get_index() {
    # shellcheck disable=SC2016
    local __doc__='
    Get index of value in an array

    >>>a=(one two three)
    >>>array_get_index one ${a[@]}
    0
    >>>a=(one two three)
    >>>array_get_index bar foo bar baz
    1
    '
    local value="$1"
    shift
    local array=("$@")
    local -i index=-1
    local i
    for i in "${!array[@]}"; do
        if [[ "${array[$i]}" == "${value}" ]]; then
            local index="${i}"
        fi
    done
    echo "$index"
    if (( index == -1 )); then
        return 1
    fi
}
array_filter() {
    # shellcheck disable=SC2016,SC2034
    local __doc__='
    >>>a=(one two three wolf)
    >>>b=( $(array_filter ".*wo.*" ${a[@]}) )
    >>>echo ${b[*]}
    two wolf'
    local pattern="$1"
    shift
    local array=( $@ )
    local element
    for element in "${array[@]}"; do
        echo "$element"
    done | grep -e "$pattern"
}
alias array.get_index="array_get_index"
