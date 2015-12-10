#!/usr/bin/sh
if [ ${#core_imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi

shopt -s expand_aliases

core_sourcer_dirname="$(cd $(dirname "${BASH_SOURCE[1]}"); pwd)"
core_sourcer_filename="$(basename "${BASH_SOURCE[1]}")"
core_imported_modules=("${core_sourcer_dirname}/${core_sourcer_filename}")

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
        [[ "$loaded_module" == "$module_path" ]] && return 0
    done

    core_check_namespace ${module%.*}
    core_imported_modules+=("$module_path")

    source "$module_path"
}
core_check_namespace() {
    local namespace="$1"
    local variable_or_function
    for variable_or_function in $({ declare -p; declare -F; } | cut -d' ' -f3- ); do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            if declare -f -F logging_log > /dev/null; then
                logging_log warn "Namespace '$namespace' is not clean:" \
                    " '$variable_or_function' is defined"
            else
                echo "WARN: Namespace '$namespace' is not clean:" \
                    " '$variable_or_function' is defined"
            fi
        fi
    done
}
alias core.import="core_import"
