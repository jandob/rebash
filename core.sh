#!/usr/bin/sh
if [ ${#core__imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi

shopt -s expand_aliases

core__sourcer_filename=$(basename "${BASH_SOURCE[1]}")
core__sourcer_module_name="${core__sourcer_filename%.*}"
core__imported_modules=($core__sourcer_module_name)
core_import() {
    local module="$1"
    # check if module already loaded
    for loaded_module in ${core__imported_modules[@]}; do
        [[ "$loaded_module" == "$module" ]] && return 0
    done
    core__imported_modules+=("$module")
    source $(dirname ${BASH_SOURCE[0]})/${module}.sh
}
core_check_namespace() {
    local namespace="$1"
    for variable_or_function in $(set); do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            return 1
        fi
    done
}
alias core.import="core_import"
alias core.check_namespace="core_check_namespace"
