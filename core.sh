#!/usr/bin/bash
if [ ${#core__imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi
core.check_namespace() {
    local namespace="$1"
    for variable_or_function in $(set); do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            return 1
        fi
    done
}
core.get_index() {
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

core__imported_modules=()
core.import() {
    local module="$1"
    if [ $(core.get_index "$module" ${core__imported_modules[@]}) -eq -1 ]; then
        core__imported_modules+="$module"
        source $(dirname $0)/${1}.sh
    else
        return 0
    fi
}
