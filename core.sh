#!/usr/bin/sh
if [ ${#core_imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi

shopt -s expand_aliases

core_sourcer_filename=$(basename "${BASH_SOURCE[1]}")
core_sourcer_module_name="${core_sourcer_filename%.*}"
core_imported_modules=($core_sourcer_module_name)
core_import() {
    local module="$1"
    local module_path=""
    local path="$(dirname ${BASH_SOURCE[0]})"
    # try absolute
    if [[ $module == /* ]] && [ -e "$module" ];then
        module_path="$module"
        module=$(basename "$module_path")
    fi
    # todo try relative
    # try rebash modules
    if [ -e "$path"/"$module".sh ]; then
        module_path="$path"/"$module".sh
    fi

    if [ "$module_path" = "" ]; then
        return 1
    fi

    # check if module already loaded
    local loaded_module
    for loaded_module in ${core_imported_modules[@]}; do
        [[ "$loaded_module" == "$module" ]] && return 0
    done

    core_check_namespace $module
    core_imported_modules+=("$module")

    source "$module_path"
}
core_check_namespace() {
    local namespace="$1"
    local variable_or_function
    for variable_or_function in $(set); do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            return 1
        fi
    done
}
alias core.import="core_import"
