#!/usr/bin/sh
source $(dirname ${BASH_SOURCE[0]})/core.sh

array_get_index() {
    __doc__='
    Get index of value in an array

    >>>a=(one two three)
    >>>array_get_index one ${a[@]}
    0
    >>>a=(one two three)
    >>>array_get_index bar foo bar hans
    1
    '
    local value="$1"
    shift
    local array=("$@")
    local index=-1
    local i
    for i in "${!array[@]}"; do
        if [[ "${array[$i]}" == "${value}" ]]; then
            local index="${i}"
        fi
    done
    echo $index
    if (( $index == -1 )); then
        return -1
    fi
}
alias array.get_index="array_get_index"
