#!/usr/bin/env bash
# shellcheck source=./core.sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.import array

arguments_new_arguments=()
arguments_set() {
    local __doc__='
    ```
    arguments.set argument1 argument2 ...
    ```

    Set the array the arguments-module is working on. After getting the desired
    arguments, the new argument array can be accessed via
    `arguments_new_arguments`. This new array contains all remaining arguments.

    '
    arguments_new_arguments=("$@")

}
arguments_get_flag() {
    local __doc__='
    ```
    arguments.get_flag flag [flag_aliases...] variable_name
    ```

    Sets `variable_name` to true if flag (or on of its aliases) is contained in
    the argument array (see `arguments.set`)

    #### Example
    ```
    arguments.get_flag verbose --verbose -v verbose_is_set
    ```

    #### Tests
    >>> arguments.set other_param1 --foo other_param2
    >>> local foo bar
    >>> arguments.get_flag --foo -f foo
    >>> echo $foo
    >>> arguments.get_flag --bar bar
    >>> echo $bar
    >>> echo "${arguments_new_arguments[@]}"
    true
    false
    other_param1 other_param2

    >>> arguments.set -f
    >>> local foo
    >>> arguments.get_flag --foo -f foo
    >>> echo $foo
    true
    '
    local variable match argument flag
    local flag_aliases=($(array.slice :-1 "$@"))
    variable="$(array.slice -1 "$@")"
    local new_arguments=()
    eval "${variable}=false"
    for argument in "${arguments_new_arguments[@]}"; do
        match=false
        for flag in "${flag_aliases[@]}"; do
            if [[ "$argument" == "$flag" ]]; then
                match=true
                eval "${variable}=true"
            fi
        done
        $match || new_arguments+=( "$argument" )
    done
    arguments_new_arguments=( "${new_arguments[@]}" )
}
arguments_get_keyword() {
    local __doc__='
    ```
    arguments.get_keyword keyword variable_name
    ```

    Sets `variable_name` to the "value" of `keyword` the argument array (see
    `arguments.set`) contains "keyword=value".

    #### Example
    ```
    arguments.get_keyword log loglevel
    ```
    #### Tests
    >>> local foo
    >>> arguments.set other_param1 foo=bar baz=baz other_param2
    >>> arguments.get_keyword foo foo
    >>> echo $foo
    >>> echo "${arguments_new_arguments[@]}"
    bar
    other_param1 baz=baz other_param2
    '
    local keyword="$1"
    local variable="$1"
    [ ! -z "$2" ] && variable="$2"
    local argument key value
    local new_arguments=()
    for argument in "${arguments_new_arguments[@]}"; do
        if [[ "$argument" == *=* ]]; then
            IFS="=" read -r key value <<<"$argument"
            if [[ "$key" == "$keyword" ]]; then
                eval "${variable}=$value"
            else
                new_arguments+=( "$argument" )
            fi
        else
            new_arguments+=( "$argument" )
        fi
    done
    arguments_new_arguments=( "${new_arguments[@]}" )
}
arguments_get_parameter() {
    local __doc__='
    ```
    arguments.get_parameter parameter [parameter_aliases...] variable_name
    ```

    Sets `variable_name` to the field following `parameter` (or one of the
    `parameter_aliases`) from the argument array (see `arguments.set`).

    #### Example
    ```
    arguments.get_parameter --log-level -l loglevel
    ```

    #### Tests
    >>> local foo
    >>> arguments.set other_param1 --foo bar other_param2
    >>> arguments.get_parameter --foo -f foo
    >>> echo $foo
    >>> echo "${arguments_new_arguments[@]}"
    bar
    other_param1 other_param2
    '
    local parameter_aliases parameter variable argument index match
    parameter_aliases=($(array.slice :-1 "$@"))
    variable="$(array.slice -1 "$@")"
    match=false
    local new_arguments=()
    for index in "${!arguments_new_arguments[@]}"; do
        argument="${arguments_new_arguments[$index]}"
        $match && match=false && continue
        match=false
        for parameter in "${parameter_aliases[@]}"; do
            if [[ "$argument" == "$parameter" ]]; then
                eval "${variable}=${arguments_new_arguments[((index+1))]}"
                match=true
                break
            fi
        done
        $match || new_arguments+=( "$argument" )
    done
    arguments_new_arguments=( "${new_arguments[@]}" )
}

alias arguments.set="arguments_set"
alias arguments.get_flag="arguments_get_flag"
alias arguments.get_keyword="arguments_get_keyword"
alias arguments.get_parameter="arguments_get_parameter"
