#!/bin/env bash
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.import logging

exceptions__doc__='
    >>> exceptions_activate
    >>> fail() { return 1; }
    >>> fail
    +doc_test_ellipsis
    Traceback (most recent call first):
    ...
'
exceptions_active=false
exceptions_debug_handler() {
    #echo DEBUG: $(caller) ${BASH_SOURCE[2]}
    printf "# endregion\n"
    printf "# region: %s\n" "$BASH_COMMAND"
}
exceptions_exit_handler() {
    logging.error "EXIT HANDLER"
    #echo DEBUG: $(caller) ${BASH_SOURCE[2]}
}
exceptions_error_handler() {
    local error_code=$?
    logging.plain "Traceback (most recent call first):"
    local -i i=0
    while caller $i > /dev/null
    do
        local -a trace=( $(caller $i) )
        local line=${trace[0]}
        local subroutine=${trace[1]}
        local filename=${trace[2]}
        logging.plain "[$i] ${filename}:${line}: ${subroutine}"
        ((i++))
    done
    if $exceptions_exit_on_error; then
        exit $error_code
    fi
}
exceptions_deactivate() {
    [ "$exceptions_errtrace_saved" = "off" ] && set +o errtrace
    [ "$exceptions_pipefail_saved" = "off" ] && set +o pipefail
    export PS4="$exceptions_ps4_saved"
    trap "$exceptions_err_traps" ERR
    exceptions_active=false
}
exceptions_activate() {
    local __doc__='
    >>> exceptions.activate
    >>> echo $exceptions_exit_on_error
    true
    >>> exceptions.activate false
    >>> echo $exceptions_exit_on_error
    false
    '
    exceptions_exit_on_error=true
    ! [ -z "$1" ] && exceptions_exit_on_error="$1"
    $exceptions_active && return 0

    exceptions_errtrace_saved=$(set -o | awk '/errtrace/ {print $2}')
    exceptions_pipefail_saved=$(set -o | awk '/pipefail/ {print $2}')
    exceptions_ps4_saved="$PS4"
    exceptions_err_traps=$(trap -p ERR | cut -d "'" -f2)

    # improve xtrace output (set -x)
    export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

    # If set, any trap on DEBUG and RETURN are inherited by shell functions,
    # command substitutions, and commands executed in a subshell environment.
    # The DEBUG and RETURN traps are normally not inherited in such cases.
    set -o errtrace
    # If set, any trap on ERR is inherited by shell functions,
    # command substitutions, and commands executed in a subshell environment.
    # The ERR trap is normally not inherited in such cases.
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

alias exceptions.activate="exceptions_activate"
alias exceptions.deactivate="exceptions_deactivate"
