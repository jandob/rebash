#!/usr/bin/env bash
if [ ${#core_imported_modules[@]} -ne 0 ]; then
    # load core only once
    return 0
fi

shopt -s expand_aliases
#TODO use set -o nounset

core_is_main() {
    local __doc__='
    Returns true if current script is being executed.

    >>> core.is_main && echo yes
    yes

    '
    [[ "${BASH_SOURCE[1]}" = "$0" ]]
}
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
core_rel_path() {
    local __doc__='
    Computes relative path from $1 to $2.

    >>> core_rel_path "/A/B/C" "/A"
    ../..
    >>> core_rel_path "/A/B/C" "/A/B"
    ..
    >>> core_rel_path "/A/B/C" "/A/B/C"
    .
    >>> core_rel_path "/A/B/C" "/A/B/C/D"
    D
    >>> core_rel_path "/A/B/C" "/A/B/C/D/E"
    D/E
    >>> core_rel_path "/A/B/C" "/A/B/D"
    ../D
    >>> core_rel_path "/A/B/C" "/A/B/D/E"
    ../D/E
    >>> core_rel_path "/A/B/C" "/A/D"
    ../../D
    >>> core_rel_path "/A/B/C" "/A/D/E"
    ../../D/E
    >>> core_rel_path "/A/B/C" "/D/E/F"
    ../../../D/E/F
    '
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    local source="$1"
    local target="$2"
    realpath --relative-to="$source" --canonicalize-missing "$target"
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

    >>> local foo="bar"
    >>> core_is_empty foo; echo $?
    1
    >>> local defined_and_empty=""
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

    >>> local foo="bar"
    >>> core_is_defined foo; echo $?
    >>> [[ -v foo ]]; echo $?
    0
    0
    >>> local defined_but_empty=""
    >>> core_is_defined defined_but_empty; echo $?
    0
    >>> core_is_defined undefined_variable; echo $?
    1
    >>> set -u
    >>> core_is_defined undefined_variable; echo $?
    1

    Same Tests for bash < 4.2
    >>> core__bash_version_test=true
    >>> local foo="bar"
    >>> core_is_defined foo; echo $?
    0
    >>> core__bash_version_test=true
    >>> local defined_but_empty=""
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
    local __doc__='
    Return all declared variables and function in the current
    scope.

    E.g.
    `declarations="$(core.get_all_declared_names)"`
    '
    (
    declare -F | cut -d' ' -f3- | cut -d'=' -f1
    declare -p | grep '^declare' | cut -d' ' -f3- | cut -d'=' -f1
    ) | sort -u
}
core_source_with_namespace_check() {
    local module_path="$1"
    local namespace="$2"
    local declarations_after
    core_declared_functions_before="$(declare -F | cut -d' ' -f3)"
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
    declarations_diff="$(! diff "$core_declarations" "$declarations_after" \
        | grep -e "^>" | sed 's/^> //')"
    for variable_or_function in $declarations_diff; do
        if ! [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            core_log warn "module '$namespace' defines unprefixed" \
                    "name: '$variable_or_function'"
        fi
    done
    core_get_all_declared_names > "$core_declarations"
    if [ "$core_import_level" = '0' ]; then
        rm "$core_declarations"
        core_declarations=""
        # shellcheck disable=SC2034
        core_declared_functions_after_import="$(! diff \
            <(echo "$core_declared_functions_before") \
            <(declare -F | cut --delimiter ' ' --fields 3) | grep '^>' | \
            sed 's/^> //'
        )"
    fi
    if (( $core_import_level == 1 )); then
        core_declared_functions_before="$(declare -F | cut --delimiter ' ' \
            --fields 3)"
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
    if [[ $module == /* ]] && [[ -e "$module" ]];then
        module_path="$module"
        module=$(basename "$module_path")
    fi
    # try relative
    if [[ -e "${caller_path}/${module}" ]]; then
        module_path="${caller_path}/${module}"
        module="$(basename "$module_path")"
    fi
    # try rebash modules
    if [[ -e "${path}/${module}.sh" ]]; then
        module_path="${path}/${module}.sh"
    fi

    if [ "$module_path" = '' ]; then
        core_log critical "failed to import \"$module\""
        return 1
    fi
    # check if module already loaded
    local loaded_module
    for loaded_module in "${core_imported_modules[@]}"; do
        if [[ "$loaded_module" == "$module_path" ]];then
            (( core_import_level == 0 )) && \
                core_declared_functions_after_import=''
            return 0
        fi
    done

    core_imported_modules+=("$module_path")
    core_source_with_namespace_check "$module_path" "${module%.sh}"
}

core_unique() {
    local __doc__='
    >>> local foo="a\nb\na\nb\nc\nb\nc"
    >>> echo -e "$foo" | core.unique
    a
    b
    c
    '
    nl "$@" | sort --key 2 | uniq --skip-fields 1 | sort --numeric-sort | \
        sed 's/\s*[0-9]\+\s\+//'
}
alias core.import="core_import"
alias core.abs_path="core_abs_path"
alias core.rel_path="core_rel_path"
alias core.is_main="core_is_main"
alias core.get_all_declared_names="core_get_all_declared_names"
alias core.unique="core_unique"
