#!/usr/bin/env bash
if [ ${#core_imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi

shopt -s expand_aliases
#TODO use set -o nounset

core_abs_path() {
    local path="$1"
    if [ -d "$path" ]; then
        local abs_path_dir
        abs_path_dir="$(cd "$path" && pwd)"
        echo "${abs_path_dir}"
    else
        local file_name
        local abs_path_dir
        file_name="$(basename "$path")"
        path=$(dirname "$path")
        abs_path_dir="$(cd "$path" && pwd)"
        echo "${abs_path_dir}/${file_name}"
    fi
}

core_imported_modules=("$(core_abs_path "${BASH_SOURCE[0]}")")
core_imported_modules+=("$(core_abs_path "${BASH_SOURCE[1]}")")
core_declarations=""
core_import_level=0

core_log() {
    if declare -f -F logging_log > /dev/null; then
        logging_log "$@"
    else
        local level=$1
        shift
        echo "$level": "$@"
    fi
}
core_is_empty() {
    local __doc__='
    Tests if variable is empty (undefined variables are not empty)

    >>> foo="bar"
    >>> core_is_empty foo; echo $?
    1
    >>> defined_and_empty=""
    >>> core_is_empty defined_and_empty; echo $?
    0
    >>> core_is_empty undefined_variable; echo $?
    1

    >>> set -u
    >>> core_is_empty undefined_variable; echo $?
    1
    '
    local variable_name="$1"
    core_is_defined "$variable_name" || return 1
    [ -z "${!variable_name}" ] || return 1
}
core_is_defined() {
    # shellcheck disable=SC2034
    local __doc__='
    Tests if variable is defined (can alo be empty)

    >>> foo="bar"
    >>> core_is_defined foo; echo $?
    >>> [[ -v foo ]]; echo $?
    0
    >>> defined_but_empty=""
    >>> core_is_defined defined_but_empty; echo $?
    0
    >>> core_is_defined undefined_variable; echo $?
    1
    >>> set -u
    >>> core_is_defined undefined_variable; echo $?
    1

    Same Tests for bash < 4.2
    >>> core__bash_version_test=true
    >>> foo="bar"
    >>> core_is_defined foo; echo $?
    0
    >>> core__bash_version_test=true
    >>> defined_but_empty=""
    >>> core_is_defined defined_but_empty; echo $?
    0
    >>> core__bash_version_test=true
    >>> core_is_defined undefined_variable; echo $?
    1
    >>> core__bash_version_test=true
    >>> set -u
    >>> core_is_defined undefined_variable; echo $?
    1
    '
    if ((BASH_VERSINFO[0] >= 4)) && ((BASH_VERSINFO[1] >= 2)) \
            && [ -z "${core__bash_version_test:-}" ]; then
        [ -v "$1" ] || return 1
    else # for bash < 4.2
        # Note: ${varname:-foo} expands to foo if varname is unset or set to the
        # empty string; ${varname-foo} only expands to foo if varname is unset.
        # shellcheck disable=SC2016
        eval '! [[ "${'"$1"'-this_variable_is_undefined_!!!}"' \
            ' == "this_variable_is_undefined_!!!" ]]'
        return $?
    fi
}
core_get_all_declared_names() {
    (
    declare -F | cut -d' ' -f3- | cut -d'=' -f1

    IFS=$'\n'
    for var in $( declare -p | cut -d' ' -f3- | cut -d'=' -f1 );do
        [ -z "${!var}" ] || echo "$var"
    done
    ) | sort -u
}
core_source_with_namespace_check() {
    local module_path="$1"
    local namespace="$2"
    local declarations_after
    declarations_after="$(mktemp)"
    if [ "$core_declarations" = "" ]; then
        core_declarations="$(mktemp)"
    fi
    # check if namespace clean before sourcing
    local variable_or_function
    core_get_all_declared_names > "$core_declarations"
    for core_variable in $core_declarations; do
        if [[ $core_variable =~ ^${namespace}[._]* ]]; then
            core_log warn "Namespace '$namespace' is not clean:" \
                "'$core_variable' is defined"
        fi
    done
    core_import_level=$((core_import_level+1))
    # shellcheck disable=1090
    source "$module_path"
    core_import_level=$((core_import_level-1))
    # check if sourcing defined unprefixed names
    core_get_all_declared_names > "$declarations_after"
    local declarations_diff
    declarations_diff="$( ! diff "$core_declarations" "$declarations_after" \
        | grep -e "^>" | sed 's/^> //')"
    for variable_or_function in $declarations_diff; do
        if ! [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            core_log warn "module '$namespace' defines unprefixed" \
                    "name: '$variable_or_function'"
        fi
    done
    core_get_all_declared_names > "$core_declarations"
    if [ "$core_import_level" = "0" ]; then
        rm "$core_declarations"
        core_declarations=""
    fi
    rm "$declarations_after"
}
core_import() {
    local module="$1"
    local module_path=""
    local path
    path="$(core_abs_path "$(dirname "${BASH_SOURCE[0]}")")"
    local caller_path
    caller_path="$(core_abs_path "$(dirname "${BASH_SOURCE[1]}")")"
    # try absolute
    if [[ $module == /* ]] && [ -e "$module" ];then
        module_path="$module"
        module=$(basename "$module_path")
    fi
    # try relative
    if [[ -e "$caller_path"/"$module" ]]; then
        module_path="$caller_path"/"$module"
        module=$(basename "$module_path")
    fi
    # try rebash modules
    if [ -e "$path"/"$module".sh ]; then
        module_path="$path"/"$module".sh
    fi

    if [ "$module_path" = "" ]; then
        core_log critical "failed to import '$1'"
        return 1
    fi
    # check if module already loaded
    local loaded_module
    for loaded_module in "${core_imported_modules[@]}"; do
        [[ "$loaded_module" == "$module_path" ]] && return 0
    done

    core_imported_modules+=("$module_path")
    core_source_with_namespace_check "$module_path" "${module%.sh}"
    #core_check_namespace ${module%.*}

    #source "$module_path"
}
alias core.import="core_import"
