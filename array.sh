#!/usr/bin/bash
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.check_namespace 'array'

array.get_index() {
    local value="$1"
    shift
    local array=("$@")
    local index=-1
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
