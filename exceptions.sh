# WORK IN PROGRESS TODO TODO TODO
function DumpBacktrace()
{
    startFrom=1
    local IFS=$' \t\n'

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

function debug_handler() {
    #echo DEBUG: $(caller) ${BASH_SOURCE[2]}
    printf "# endregion\n"
    printf "# region: %s\n" "$BASH_COMMAND"
}
function exit_handler() {
    #echo DEBUG: $(caller) ${BASH_SOURCE[2]}
    printf "# endregion\n"
}
function error_handler() {
    error_code=$?
    restore_logging
    DumpBacktrace
    JOB="$0"              # job name
    LASTLINE="$1"         # line of error occurrence
    LASTERR="$2"          # error code
    echo "ERROR in ${JOB} : line ${LASTLINE} with exit code ${LASTERR}"
    exit $error_code
}
set -o errtrace # If set, any trap on DEBUG and RETURN are inherited by shell functions, command substitutions, and commands executed in a subshell environment. The DEBUG and RETURN traps are normally not inherited in such cases.
set -o pipefail # If set, any trap on ERR is inherited by shell functions, command substitutions, and commands executed in a subshell environment. The ERR trap is normally not inherited in such cases.
#set -o nounset
#set -o errexit
# traps:
# EXIT      executed on shell exit
# DEBUG	    executed before every simple command
# RETURN    executed when a shell function or a sourced code finishes executing
# ERR       executed each time a command's failure would cause the shell to exit when the '-e' option ('errexit') is enabled
#trap error_handler ERR
#trap debug_handler DEBUG
#trap exit_handler EXIT

#echo A
#echo B
#echo C
