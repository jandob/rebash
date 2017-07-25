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

    >>> # Note: this test passes because is_main is called by doc_test.sh which
    >>> # is being executed.
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
    # shellcheck disable=SC2016
    local __doc__='
    Computes relative path from $1 to $2.
    Taken from http://stackoverflow.com/a/12498485/2972353

    >>> core_rel_path "/A/B/C" "/A"
    ../..
    >>> core_rel_path "/A/B/C" "/A/B"
    ..
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
    >>> core_rel_path "/" "/"
    .
    >>> core_rel_path "/A/B/C" "/A/B/C"
    .
    >>> core_rel_path "/A/B/C" "/"
    ../../../
    '
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    local source="$1"
    local target="$2"
    if [[ "$source" == "$target" ]]; then
        echo "."
        return
    fi

    local common_part="$source" # for now
    local result="" # for now

    while [[ "${target#$common_part}" == "${target}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname "$common_part")"
        # and record that we went back, with correct / handling
        if [[ -z $result ]]; then
            result=".."
        else
            result="../$result"
        fi
    done

    if [[ $common_part == "/" ]]; then
        # special case for root (no common path)
        result="$result/"
    fi

    # since we now have identified the common part,
    # compute the non-common part
    local forward_part="${target#$common_part}"

    # and now stick all parts together
    if [[ -n $result ]] && [[ -n $forward_part ]]; then
        result="$result$forward_part"
    elif [[ -n $forward_part ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi
    echo "$result"
}

core_imported_modules=("$(core_abs_path "${BASH_SOURCE[0]}")")
core_imported_modules+=("$(core_abs_path "${BASH_SOURCE[1]}")")
core_declarations_before=""
core_declared_functions_after_import=""
core_import_level=0

core_log() {
    if type -t logging_log > /dev/null; then
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
    Tests if variable is defined (can also be empty)

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
    >>> set -o nounset
    >>> core_is_defined undefined_variable; echo $?
    1

    Same Tests for bash < 4.3
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
    >>> set -o nounset
    >>> core_is_defined undefined_variable; echo $?
    1
    '
    (
    set +o nounset
    if ((BASH_VERSINFO[0] >= 4)) && ((BASH_VERSINFO[1] >= 3)) \
            && [ -z "${core__bash_version_test:-}" ]; then
        [[ -v "${1:-}" ]] || exit 1
    else # for bash < 4.3
        # Note: ${varname:-foo} expands to foo if varname is unset or set to the
        # empty string; ${varname-foo} only expands to foo if varname is unset.
        # shellcheck disable=SC2016
        eval '! [[ "${'"${1}"'-this_variable_is_undefined_!!!}"' \
            ' == "this_variable_is_undefined_!!!" ]]'
        exit $?
    fi
    )
}
core_get_all_declared_names() {
    # shellcheck disable=SC2016
    local __doc__='
    Return all declared variables and function in the current scope.

    E.g.
    `declarations="$(core.get_all_declared_names)"`
    '
    local only_functions="${1:-}"
    [ -z "$only_functions" ] && only_functions=false
    {
    declare -F | cut --delimiter ' ' --fields 3
    $only_functions || declare -p | grep '^declare' \
        | cut --delimiter ' ' --fields 3 - | cut --delimiter '=' --fields 1
    } | sort --unique
}
core_get_all_aliases() {
    local __doc__='
    Returns all defined aliases in the current scope.
    '
    alias | grep '^alias' \
        | cut --delimiter ' ' --fields 2 - | cut --delimiter '=' --fields 1
}
core_source_with_namespace_check() {
    local __doc__='
    Sources a script and checks variable definitions before and after sourcing.
    '
    # TODO make sure sourcing a file does not change the value of already
    # defined variables.
    local module_path="$1"
    local namespace="$2"
    local declarations_after declarations_diff
    [ "$core_import_level" = '0' ] && \
        core_declared_functions_before="$(mktemp --suffix=rebash-core-before)"
    core_get_all_declared_names true > "$core_declared_functions_before"
    declarations_after="$(mktemp --suffix=rebash-core-dec-after)"
    if [ "$core_declarations_before" = "" ]; then
        core_declarations_before="$(mktemp --suffix=rebash-core-dec)"
    fi
    # region check if namespace clean before sourcing
    local variable_or_function core_variable
    core_get_all_declared_names > "$core_declarations_before"
    while read -r variable_or_function ; do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            core_log warn "Namespace '$namespace' is not clean:" \
                "'$variable_or_function' is defined" 1>&2
        fi
    done < "$core_declarations_before"
    # endregion

    core_import_level=$((core_import_level+1))
    # shellcheck disable=1090
    source "$module_path"
    [ $? = 1 ] && core_log critical "Failed to source $module_path" && exit 1
    core_import_level=$((core_import_level-1))

    # check if sourcing defined unprefixed names
    core_get_all_declared_names > "$declarations_after"
    if ! $core_suppress_declaration_warning; then
        declarations_diff="$(! diff "$core_declarations_before" \
            "$declarations_after" | grep -e "^>" | sed 's/^> //')"
        for variable_or_function in $declarations_diff; do
            if ! [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
                core_log warn "module \"$namespace\" defines unprefixed" \
                        "name: \"$variable_or_function\"" 1>&2
            fi
        done
    fi
    core_get_all_declared_names > "$core_declarations_before"
    if [ "$core_import_level" = '0' ]; then
        rm "$core_declarations_before"
        core_declarations_before=""
        core_declared_functions_after="$(mktemp --suffix=rebash-core-after)"
        core_get_all_declared_names true > "$core_declared_functions_after"
        core_declared_functions_after_import="$(! diff \
            "$core_declared_functions_before" \
            "$core_declared_functions_after" \
            | grep '^>' | sed 's/^> //'
        )"
        rm "$core_declared_functions_after"
        rm "$core_declared_functions_before"
    fi
    if (( core_import_level == 1 )); then
        declare -F | cut --delimiter ' ' --fields 3 \
            > "$core_declared_functions_before"
    fi
    rm "$declarations_after"
}
core_suppress_declaration_warning=false
core_import() {
    # shellcheck disable=SC2016,SC1004
    local __doc__='
    IMPORTANT: Do not use core.import inside functions -> aliases do not work
    TODO: explain this in more detail

    >>> (
    >>> core.import logging
    >>> logging_set_level warn
    >>> core.import test/mockup_module-b.sh false
    >>> )
    +doc_test_contains
    imported module c
    module "mockup_module_c" defines unprefixed name: "foo123"
    imported module b

    Modules should be imported only once.
    >>> (core.import test/mockup_module_a.sh && \
    >>>     core.import test/mockup_module_a.sh)
    imported module a

    >>> (
    >>> core.import test/mockup_module_a.sh false
    >>> echo $core_declared_functions_after_import
    >>> )
    imported module a
    mockup_module_a_foo

    >>> (
    >>> core.import logging
    >>> logging_set_level warn
    >>> core.import test/mockup_module_c.sh false
    >>> echo $core_declared_functions_after_import
    >>> )
    +doc_test_contains
    imported module b
    imported module c
    module "mockup_module_c" defines unprefixed name: "foo123"
    foo123

    '
    local module="$1"
    local suppress_declaration_warning="${2:-}"
    # If "$suppress_declaration_warning" is empty do not change the current value
    # of "$core_suppress_declaration_warning". (So it is not changed by nested
    # imports.)
    if [[ "$suppress_declaration_warning" == "true" ]]; then
        core_suppress_declaration_warning=true
    elif [[ "$suppress_declaration_warning" == "false" ]]; then
        core_suppress_declaration_warning=false
    fi
    local module_path=""
    local path
    # shellcheck disable=SC2034
    core_declared_functions_after_import=""

    path="$(core_abs_path "$(dirname "${BASH_SOURCE[0]}")")"
    local caller_path
    caller_path="$(core_abs_path "$(dirname "${BASH_SOURCE[1]}")")"
    # try absolute
    if [[ $module == /* ]] && [[ -e "$module" ]];then
        module_path="$module"
    fi
    # try relative
    if [[ -f "${caller_path}/${module}" ]]; then
        module_path="${caller_path}/${module}"
    fi
    # try rebash modules
    if [[ -f "${path}/${module%.sh}.sh" ]]; then
        module_path="${path}/${module%.sh}.sh"
    fi

    if [ "$module_path" == "" ]; then
        core_log critical "failed to import \"$module\""
        return 1
    fi

    module="$(basename "$module_path")"

    # normalize module_path
    module_path="$(core.abs_path "$module_path")"
    # check if module already loaded
    local loaded_module
    for loaded_module in "${core_imported_modules[@]}"; do
        if [[ "$loaded_module" == "$module_path" ]];then
            (( core_import_level == 0 )) && \
                core_declarations_before=''
            return 0
        fi
    done

    core_imported_modules+=("$module_path")
    core_source_with_namespace_check "$module_path" "${module%.sh}"
}
core_unique() {
    # shellcheck disable=SC2034,SC2016
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
alias core.is_defined="core_is_defined"
alias core.is_empty="core_is_empty"

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
