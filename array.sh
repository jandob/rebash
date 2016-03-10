#!/usr/bin/env bash
# shellcheck source=./core.sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
# shellcheck disable=SC2034
array__doc_test_setup__='
    doc_test_strict_declaration_check=true
'
array_get_index() {
    # shellcheck disable=SC2016
    local __doc__='
    Get index of value in an array

    >>> local a=(one two three)
    >>> array_get_index one ${a[@]}
    0
    >>> local a=(one two three)
    >>> array_get_index bar foo bar baz
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
    >>> local a=(one two three wolf)
    >>> local b=( $(array_filter ".*wo.*" ${a[@]}) )
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
