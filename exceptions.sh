#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
core.import logging

# shellcheck disable=SC2034,SC2016
exceptions__doc__='
    NOTE: The try block is executed in a subshell, so no outer variables can be
    assigned.

    >>> exceptions.activate
    >>> false
    +doc_test_ellipsis
    Traceback (most recent call first):
    ...

    >>> exceptions_activate
    >>> exceptions.try {
    >>>     false
    >>> }; exceptions.catch {
    >>>     echo caught
    >>> }
    caught

    Exceptions in a subshell:
    >>> exceptions_activate
    >>> ( false )
    +doc_test_ellipsis
    Traceback (most recent call first):
    ...
    Traceback (most recent call first):
    ...
    >>> exceptions_activate
    >>> exceptions.try {
    >>>     (false; echo "this should not be printed")
    >>>     echo "this should not be printed"
    >>> }; exceptions.catch {
    >>>     echo caught
    >>> }
    +doc_test_ellipsis
    caught

    Nested exceptions:
    >>> exceptions_foo() {
    >>>     true
    >>>     exceptions.try {
    >>>         false
    >>>     }; exceptions.catch {
    >>>         echo caught inside foo
    >>>     }
    >>>     false # this is cought at top level
    >>>     echo this should never be printed
    >>> }
    >>>
    >>> exceptions.try {
    >>>     exceptions_foo
    >>> }; exceptions.catch {
    >>>     echo caught
    >>> }
    >>>
    caught inside foo
    caught

    Exceptions are implicitely active inside try blocks:
    >>> foo() {
    >>>     echo $1
    >>>     true
    >>>     exceptions.try {
    >>>         false
    >>>     }; exceptions.catch {
    >>>         echo caught inside foo
    >>>     }
    >>>     false # this is not caught
    >>>     echo this should never be printed
    >>> }
    >>>
    >>> foo "EXCEPTIONS NOT ACTIVE:"
    >>> exceptions_activate
    >>> foo "EXCEPTIONS ACTIVE:"
    +doc_test_ellipsis
    EXCEPTIONS NOT ACTIVE:
    caught inside foo
    this should never be printed
    EXCEPTIONS ACTIVE:
    caught inside foo
    Traceback (most recent call first):
    ...

    Exceptions inside conditionals:
    >>> exceptions_activate
    >>> false && echo "should not be printed"
    >>> (false) && echo "should not be printed"
    >>> exceptions.try {
    >>>     (
    >>>     false
    >>>     echo "should not be printed"
    >>>     )
    >>> }; exceptions.catch {
    >>>     echo caught
    >>> }
    caught

    Reraise exception
    >>> exceptions.try {
    >>>     false
    >>> }; exceptions.catch {
    >>>     echo caught
    >>>     echo "$exceptions_last_traceback"
    >>> }
    +doc_test_ellipsis
    caught
    Traceback (most recent call first):
    ...

    >>> exceptions.try {
    >>>     ! true
    >>> }; exceptions.catch {
    >>>     echo caught
    >>> }

    >>> exceptions.try
    >>>     false
    >>> exceptions.catch {
    >>>     echo caught
    >>> }
    caught

    >>> exceptions.try
    >>>     false
    >>> exceptions.catch
    >>>     echo caught
    caught

    >>> exceptions.try {
    >>>     false
    >>> }
    >>> exceptions.catch {
    >>>     echo caught
    >>> }
    caught

    >>> exceptions.try {
    >>>     false
    >>> }
    >>> exceptions.catch
    >>> {
    >>>     echo caught
    >>> }
    caught
'
exceptions_active=false
exceptions_active_before_try=false
declare -ig exceptions_try_catch_level=0
exceptions_error_handler() {
    local error_code=$?
    local traceback="Traceback (most recent call first):"
    local -i i=0
    while caller $i > /dev/null
    do
        local -a trace=( $(caller $i) )
        local line=${trace[0]}
        local subroutine=${trace[1]}
        local filename=${trace[2]}
        traceback="$traceback"'\n'"[$i] ${filename}:${line}: ${subroutine}"
        ((i++))
    done
    if (( exceptions_try_catch_level == 0 )); then
        logging.plain "$traceback" 1>&2
    else
        logging.plain "$traceback" >"$exceptions_last_traceback_file"
    fi
    exit $error_code
}
exceptions_deactivate() {
    # shellcheck disable=SC2016,2034
    local __doc__='
    >>> set -o errtrace
    >>> trap '\''echo $foo'\'' ERR
    >>> exceptions.activate
    >>> trap -p ERR | cut --delimiter "'\''" --fields 2
    >>> exceptions.deactivate
    >>> trap -p ERR | cut --delimiter "'\''" --fields 2
    exceptions_error_handler
    echo $foo
    '
    $exceptions_active || return 0
    [ "$exceptions_errtrace_saved" = "off" ] && set +o errtrace
    [ "$exceptions_pipefail_saved" = "off" ] && set +o pipefail
    [ "$exceptions_functrace_saved" = "off" ] && set +o functrace
    export PS4="$exceptions_ps4_saved"
    # shellcheck disable=SC2064
    trap "$exceptions_err_traps" ERR
    exceptions_active=false
}
exceptions_activate() {
    $exceptions_active && return 0

    exceptions_errtrace_saved=$(set -o | awk '/errtrace/ {print $2}')
    exceptions_pipefail_saved=$(set -o | awk '/pipefail/ {print $2}')
    exceptions_functrace_saved=$(set -o | awk '/functrace/ {print $2}')
    exceptions_err_traps=$(trap -p ERR | cut --delimiter "'" --fields 2)
    exceptions_ps4_saved="$PS4"

    # improve xtrace output (set -x)
    export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

    # If set, any trap on ERR is inherited by shell functions,
    # command substitutions, and commands executed in a subshell environment.
    # The ERR trap is normally not inherited in such cases.
    set -o errtrace
    # If set, any trap on DEBUG and RETURN are inherited by shell functions,
    # command substitutions, and commands executed in a subshell environment.
    # The DEBUG and RETURN traps are normally not inherited in such cases.
    #set -o functrace
    # If set, the return value of a pipeline is the value of the last
    # (rightmost) command to exit with a non-zero status, or zero if all
    # commands in the pipeline exit successfully. This option is disabled by
    # default.
    set -o pipefail
    # Treat unset variables and parameters other than the special parameters
    # ‘@’ or ‘*’ as an error when performing parameter expansion.
    # An error message will be written to the standard error, and a
    # non-interactive shell will exit.
    #set -o nounset

    # traps:
    # EXIT      executed on shell exit
    # DEBUG	executed before every simple command
    # RETURN    executed when a shell function or a sourced code finishes executing
    # ERR       executed each time a command's failure would cause the shell to exit when the '-e' option ('errexit') is enabled

    # ERR is not executed in following cases:
    # >>> err() { return 1;}
    # >>> ! err
    # >>> err || echo foo
    # >>> err && echo foo

    trap exceptions_error_handler ERR
    #trap exceptions_debug_handler DEBUG
    #trap exceptions_exit_handler EXIT
    exceptions_active=true
}
exceptions_enter_try() {
    if (( exceptions_try_catch_level == 0 )); then
        exceptions_last_traceback_file="$(mktemp)"
        exceptions_active_before_try=$exceptions_active
    fi
    exceptions_deactivate
    exceptions_try_catch_level+=1
}
exceptions_exit_try() {
    local exceptions_result=$1
    exceptions_try_catch_level+=-1
    if (( exceptions_try_catch_level == 0 )); then
        $exceptions_active_before_try && exceptions_activate
        exceptions_last_traceback="$(
            logging.cat "$exceptions_last_traceback_file"
        )"
        rm "$exceptions_last_traceback_file"
    else
        exceptions_activate
    fi
    return $exceptions_result
}
alias exceptions.activate="exceptions_activate"
alias exceptions.deactivate="exceptions_deactivate"
alias exceptions.try='exceptions_enter_try; (exceptions_activate; '
alias exceptions.catch='true); exceptions_exit_try $? || '
