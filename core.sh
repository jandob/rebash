#!/usr/bin/bash
if [ ${#core__imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi
sourcer_filename=$(basename "${BASH_SOURCE[1]}")
sourcer_module_name="${sourcer_filename%.*}"
core__imported_modules=($sourcer_module_name)
core.import() {
    local module="$1"
    # check if module already loaded
    for loaded_module in ${core__imported_modules[@]}; do
        [[ "$loaded_module" == "$module" ]] && return 0
    done
    core__imported_modules+=("$module")
    source $(dirname ${BASH_SOURCE[0]})/${module}.sh
}
core.check_namespace() {
    local namespace="$1"
    for variable_or_function in $(set); do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            return 1
        fi
    done
}
