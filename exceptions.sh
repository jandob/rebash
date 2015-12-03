#!/usr/bin/sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.import logging

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
    logging.error "Stacktrace:"
    local -i i=0
    while caller $i > /dev/null
    do
        local -a trace=( $(caller $i) )
        local line=${trace[0]}
        local subroutine=${trace[1]}
        local filename=${trace[2]}
        logging.plain "[$i] ${filename}(${line})\t${subroutine}"
        ((i++))
    done
    exit $error_code
}
exceptions_deactivate() {
    [ "$exceptions_errtrace_saved" = "off" ] && set +o errtrace
    [ "$exceptions_pipefail_saved" = "off" ] && set +o pipefail
    export PS4="$exceptions_ps4_saved"
    trap - ERR
}
exceptions_activate() {
    exceptions_errtrace_saved=$(set -o | awk '/errtrace/ {print $2}')
    exceptions_pipefail_saved=$(set -o | awk '/pipefail/ {print $2}')
    exceptions_ps4_saved="$PS4"

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
    # >>> err || echo hans
    # >>> err && echo hans

    trap exceptions_error_handler ERR
    #trap exceptions_debug_handler DEBUG
    #trap exceptions_exit_handler EXIT
}

alias exceptions.activate="exceptions_activate"
alias exceptions.deactivate="exceptions_deactivate"
