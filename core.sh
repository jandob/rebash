#!/usr/bin/sh
if [ ${#core_imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi

shopt -s expand_aliases

core_abs_path() {
    local path="$1"
    if [ -d "$path" ]; then
        local abs_path_dir="$(cd "$path"; pwd)"
        echo "${abs_path_dir}"
    else
        local file_name="$(basename "$path")"
        path=$(dirname "$path")
        local abs_path_dir="$(cd "$path"; pwd)"
        echo "${abs_path_dir}/${file_name}"

    fi
}

core_imported_modules=("$(core_abs_path "${BASH_SOURCE[0]}")")
core_imported_modules+=("$(core_abs_path "${BASH_SOURCE[1]}")")

core_declarations_ok=""
core_source_with_namespace_check() {
    local module_path="$1"
    local namespace="$2"
    local declarations_before="$(mktemp)"
    local declarations_after="$(mktemp)"
    # check if namespace clean before sourcing
    local variable_or_function
    { declare -p; declare -F; } | cut -d' ' -f3- | cut -d'=' -f1 | sort -u > "$declarations_before"
    for variable_or_function in $declarations_before; do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            if declare -f -F logging_log > /dev/null; then
                logging_log warn "Namespace '$namespace' is not clean:" \
                    "'$variable_or_function' is defined"
            else
                echo "WARN: Namespace '$namespace' is not clean:" \
                    "'$variable_or_function' is defined"
            fi
        fi
    done
    source "$module_path"
    # TODO move down
    local declarations_before="$(mktemp)"
    local declarations_after="$(mktemp)"
    return 0
    # end TODO
    # check if sourcing defined unprefixed names
    { declare -p; declare -F; } | cut -d' ' -f3- | cut -d'=' -f1 | sort -u > "$declarations_after"
    local declarations_diff="$( diff "$declarations_before" "$declarations_after" | grep -e "^>" | sed 's/^> //')"
    echo $namespace diff:
    for variable_or_function in $declarations_diff; do
        echo $variable_or_function
        if ! [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            echo "module '$namespace' defines unprefixed" \
                    "name: '$variable_or_function'"
            if declare -f -F logging_log > /dev/null; then
                logging_log warn "module '$namespace' defines unprefixed" \
                    "name: '$variable_or_function'"
            else
                echo "module '$namespace' defines unprefixed" \
                    "name: '$variable_or_function'"
            fi
        fi
    done
}
core_import() {
    local module="$1"
    local module_path=""
    local path="$(core_abs_path "$(dirname ${BASH_SOURCE[0]})")"
    local caller_path="$(core_abs_path "$(dirname ${BASH_SOURCE[1]})")"
    # try absolute
    if [[ $module == /* ]] && [ -e "$module" ];then
        module_path="$module"
        module=$(basename "$module_path")
    fi
    # todo try relative
    if [[ -e "$caller_path"/"$module" ]]; then
        module_path="$caller_path"/"$module"
    fi
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

    core_imported_modules+=("$module_path")
    core_source_with_namespace_check "$module_path" "${module%.*}"
    #core_check_namespace ${module%.*}

    #source "$module_path"
}
core_check_namespace() {
    local namespace="$1"
    local variable_or_function
    for variable_or_function in $({ declare -p; declare -F; } | cut -d' ' -f3- ); do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            if declare -f -F logging_log > /dev/null; then
                logging_log warn "Namespace '$namespace' is not clean:" \
                    "'$variable_or_function' is defined"
            else
                echo "WARN: Namespace '$namespace' is not clean:" \
                    "'$variable_or_function' is defined"
            fi
        fi
    done
}
alias core.import="core_import"
