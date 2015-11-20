#!/usr/bin/bash
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.check_namespace 'logging'
core.import ui
core.import array

# region constants
# logging levels from low to high
logging_levels=(error critical warn info debug)
# matches the order of logging levels
logging_levels_color=(
    $ui_color_red
    $ui_color_magenta
    $ui_color_yellow
    $ui_color_cyan
    $ui_color_green
)
# endregion

# region private variables
logging__commands_level=$(array.get_index 'debug' ${logging_levels[@]})
logging__level=$(array.get_index 'debug' ${logging_levels[@]})
logging__commands_output_off=false
# endregion

# region public functions
logging.set_commands_log_level() {
    logging__commands_level=$(array.get_index "$1" ${logging_levels[@]})
}
logging.set_log_level() {
    __test__='
    logging.set_log_level info
    echo $logging__level
    >>>3
    '
    logging__level=$(array.get_index "$1" ${logging_levels[@]})
    if [ $logging__level -ge $logging__commands_level ]; then
        logging._command_output_on
    else
        logging._command_output_off
    fi
}
logging._get_log_prefix() {
    local level=$1
    local level_index=$2
    local color=${logging_levels_color[$level_index]}
    local loglevel=${color}${level}${ui_color_default}
    local info=[${loglevel}:"${BASH_SOURCE[3]##./}":${BASH_LINENO[2]}]
    echo ${info}
}
logging.log() {
    local level="$1"
    shift
    local level_index=$(array.get_index "$level" ${logging_levels[@]})
    if [ $level_index -eq -1 ]; then
        logging.warn "loglevel \"$level\" not available, use one of: ("\
            "${logging_levels[@]} )"
        return 1
    fi
    if [ $logging__level -ge $level_index ]; then
        log_prefix=$(logging._get_log_prefix $level $level_index)
        logging._log "$log_prefix" "$@"
    fi
}
logging.error() {
    logging.log 'error' "$@"
}
logging.critical() {
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
logging.plain() {
    logging._log "$@"
}
# endregion

# region private functions
logging._log() {
    if $logging__commands_output_off; then
        # explicetely print to stdout/stderr
        echo -e "$@" 1>&3 2>&4
    else
        echo -e "$@"
    fi
}
logging._command_output_off() {
    if $logging__commands_output_off; then
        return 0
    fi
    # all commands will log to /dev/null
    exec 3>&1 4>&2
    exec 1>/dev/null 2>/dev/null
    logging__commands_output_off=true
}
logging._command_output_on() {
    if ! $logging__commands_output_off; then
        return 0
    fi
    # all commands will log to /dev/stdout, /dev/stderr
    exec 1>&3 2>&4 3>&- 4>&-
    logging__commands_output_off=false
}

# endregion

# region example usage
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    logging.set_commands_log_level 'debug'
    logging.set_log_level 'debug'
    logging.error 'error'
    logging.critical 'critical'
    logging.warn 'warn'
    logging.info 'info'
    logging.debug 'debug'
    echo hans
fi
# endregion

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
