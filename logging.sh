#!/usr/bin/bash
source $(dirname $0)/core.sh
core.check_namespace 'logging'

# region constants
readonly logging_levels=(error warn info debug)
# endregion

# region private variables
logging__COMMANDS_LEVEL=$(core.get_index 'debug' ${logging_levels[@]})
logging__LEVEL=$(core.get_index 'debug' ${logging_levels[@]})
logging__COMMANDS_OUTPUT_OFF=false
# endregion

# region public functions
logging.set_commands_log_level() {
    logging__COMMANDS_LEVEL=$(core.get_index "$1" ${logging_levels[@]})
}
logging.set_log_level() {
    logging__LEVEL=$(core.get_index "$1" ${logging_levels[@]})
    if [ $logging__LEVEL -ge $logging__COMMANDS_LEVEL ]; then
        logging._command_output_on
    else
        logging._command_output_off
    fi
}
logging.log() {
    local level="$1"
    shift
    if [ $logging__LEVEL -ge $(core.get_index "$level" ${logging_levels[@]}) ];then
        logging._log "$@"
    fi
}
logging.error() {
    logging.log 'error' "$@"
}
logging.warn() {
    logging.log 'warn' "$@"
}
logging.info() {
    logging.log 'info' "$@"
}
logging.debug() {
    logging.log 'debug' "$@"
}
# endregion

# region private functions
logging._log() {
    if $logging__COMMANDS_OUTPUT_OFF; then
        # explicetely print to stdout/stderr
        echo "$@" 1>&3 2>&4
    else
        echo "$@"
    fi
}
logging._command_output_off() {
    if $logging__COMMANDS_OUTPUT_OFF; then
        return 0
    fi
    # all commands will log to /dev/null
    exec 3>&1 4>&2
    exec 1>/dev/null 2>/dev/null
    logging__COMMANDS_OUTPUT_OFF=true
}
logging._command_output_on() {
    if ! $logging__COMMANDS_OUTPUT_OFF; then
        return 0
    fi
    # all commands will log to /dev/stdout, /dev/stderr
    exec 1>&3 2>&4 3>&- 4>&-
    logging__COMMANDS_OUTPUT_OFF=false
}

# endregion

# region example usage
# >>> logging.set_commands_log_level 'info'
# >>> logging.set_log_level 'info'
# >>> logging.error 'error'
# >>> logging.warn 'warn'
# >>> logging.info 'info'
# >>> logging.debug 'debug'
# endregion

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
