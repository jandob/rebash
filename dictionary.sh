#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
core.import logging

dictionary_set() {
    local __doc__='
    Usage:
        dictionary.set dictionary_name key value

    Tests:

    >>> dictionary_set map foo 2
    >>> echo ${dictionary__store_map[foo]}
    2
    >>> dictionary_set map foo "a b c"
    >>> echo ${dictionary__store_map[foo]}
    a b c

    >>> dictionary__bash_version_test=true
    >>> dictionary_set map foo 2
    >>> echo $dictionary__store_map_foo
    2
    >>> dictionary__bash_version_test=true
    >>> dictionary_set map foo "a b c"
    >>> echo $dictionary__store_map_foo
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
    Usage:
        variable=$(dictionary.get dictionary_name key)

    Examples:

    >>> dictionary_set map foo 2
    >>> dictionary_set map bar 1
    >>> dictionary_get map foo
    >>> dictionary_get map bar
    2
    1
    >>> dictionary_set map foo "a b c"
    >>> dictionary_get map foo
    a b c
    >>> dictionary__bash_version_test=true
    >>> dictionary_set map foo 2
    >>> dictionary_get map foo
    2
    >>> dictionary__bash_version_test=true
    >>> dictionary_set map foo "a b c"
    >>> dictionary_get map foo
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
