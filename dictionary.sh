#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

dictionary_set() {
    local __doc__='
    Examples:

    >>> dictionary_set map hans 2
    >>> echo ${dictionary__store_map[hans]}
    2
    >>> dictionary_set map hans "a b c"
    >>> echo ${dictionary__store_map[hans]}
    a b c

    >>> dictionary__bash_version_test=true
    >>> dictionary_set map hans 2
    >>> echo $dictionary__store_map_hans
    2
    >>> dictionary__bash_version_test=true
    >>> dictionary_set map hans "a b c"
    >>> echo $dictionary__store_map_hans
    a b c
    '
    local name="$1"
    local key="$2"
    local value="\"$3\""
    if (($BASH_VERSINFO < 4)) \
            || ! [ -z "$dictionary__bash_version_test" ]; then
        eval "dictionary__store_${name}_${key}=""$value"
    else
        declare -Ag "dictionary__store_${name}"
        eval "dictionary__store_${name}[${key}]=""$value"
    fi
}
dictionary_get() {
    local __doc__='
    Examples:
    >>> dictionary_set map hans 2
    >>> dictionary_get map hans
    2
    >>> dictionary_set map hans "a b c"
    >>> dictionary_get map hans
    a b c
    >>> dictionary__bash_version_test=true
    >>> dictionary_set map hans 2
    >>> dictionary_get map hans
    2
    >>> dictionary__bash_version_test=true
    >>> dictionary_set map hans "a b c"
    >>> dictionary_get map hans
    a b c
    '
    local name="$1"
    local key="$2"
    if (($BASH_VERSINFO < 4)) \
            || ! [ -z "$dictionary__bash_version_test" ]; then
        local store="dictionary__store_${name}_${key}"
    else
        local store="dictionary__store_${name}[${key}]"
    fi
    echo "${!store}"
}
alias dictionary.set='dictionary_set'
alias dictionary.get='dictionary_get'
