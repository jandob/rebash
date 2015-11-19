# WORK IN PROGRESS TODO TODO TODO

exceptions._init() {
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

    trap exceptions._error_handler ERR
    #trap exceptions._debug_handler DEBUG
    #trap exceptions._exit_handler EXIT
}
exceptions._dump_backtrace()
{
    startFrom=1
    local IFS=' \t\n'

    local -i i=0

    while caller $i > /dev/null
    do
        if (( $i + 1 >= $startFrom ))
        then
            local -a trace=( $(caller $i) )

            echo "${trace[0]} ${trace[1]} ${trace[@]:2}"
        fi
        i+=1
    done
}

exception._debug_handler() {
    #echo DEBUG: $(caller) ${BASH_SOURCE[2]}
    printf "# endregion\n"
    printf "# region: %s\n" "$BASH_COMMAND"
}
exception._exit_handler() {
    #echo DEBUG: $(caller) ${BASH_SOURCE[2]}
    printf "# endregion\n"
}
exception._error_handler() {
    error_code=$?
    restore_logging
    DumpBacktrace
    JOB="$0"              # job name
    LASTLINE="$1"         # line of error occurrence
    LASTERR="$2"          # error code
    echo "ERROR in ${JOB} : line ${LASTLINE} with exit code ${LASTERR}"
    exit $error_code
}

#echo A
#echo B
#echo C
