#!/bin/env bash
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.import ui
core.import array
# region variables
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
logging_commands_level=$(array.get_index 'critical' ${logging_levels[@]})
logging_level=$(array.get_index 'critical' ${logging_levels[@]})
logging_commands_output_off=false
# endregion
# region functions
logging_set_commands_level() {
    logging_commands_level=$(array.get_index "$1" ${logging_levels[@]})
}
logging_get_level() {
    echo ${logging_levels[$logging_level]}
}
logging_get_commands_level() {
    echo ${logging_levels[$logging_commands_level]}
}
logging_set_level() {
    __doc__='
    >>>logging.set_commands_level info
    >>>logging.set_level info
    >>>echo $logging_level
    >>>echo $logging_commands_level
    3
    3
    '
    logging_level=$(array.get_index "$1" ${logging_levels[@]})
    if [ $logging_level -ge $logging_commands_level ]; then
        logging_set_command_output_on
    else
        logging_set_command_output_off
    fi
}
logging_get_prefix() {
    local level=$1
    local level_index=$2
    local color=${logging_levels_color[$level_index]}
    local loglevel=${color}${level}${ui_color_default}
    local info=[${loglevel}:"${BASH_SOURCE[2]##./}":${BASH_LINENO[1]}]
    echo ${info}
}
logging_log() {
    local level="$1"
    shift
    local level_index=$(array.get_index "$level" ${logging_levels[@]})
    if [ $level_index -eq -1 ]; then
        logging_critical "loglevel \"$level\" not available, use one of: ("\
            "${logging_levels[@]} )"
        return 1
    fi
    if [ $logging_level -ge $level_index ]; then
        prefix=$(logging_get_prefix $level $level_index)
        logging_echo "$prefix" "$@"
    fi
}
logging_cat() {
    if $logging_commands_output_off; then
        # explicetely print to stdout/stderr
        cat "$@" 1>&3 2>&4
    else
        cat "$@"
    fi
}

logging_echo() {
    if $logging_commands_output_off; then
        # explicetely print to stdout/stderr
        echo -e "$@" 1>&3 2>&4
    else
        echo -e "$@"
    fi
}
logging_set_command_output_off() {
    if $logging_commands_output_off; then
        return 0
    fi
    # all commands will log to /dev/null
    exec 3>&1 4>&2
    exec 1>/dev/null 2>/dev/null
    logging_commands_output_off=true
}
logging_set_command_output_on() {
    if ! $logging_commands_output_off; then
        return 0
    fi
    # all commands will log to /dev/stdout, /dev/stderr
    exec 1>&3 2>&4 3>&- 4>&-
    logging_commands_output_off=false
}

# endregion
# region public interface
# set global log level
alias logging.set_level='logging_set_level'
# set log level for commands
alias logging.set_commands_level='logging_set_commands_level'
alias logging.get_level='logging_get_level'
alias logging.get_commands_level='logging_get_commands_level'
# log at the different levels, prints extra info (log-level, file and linenumber)
alias logging.log='logging_log'
alias logging.error='logging_log error'
alias logging.critical='logging_log critical'
alias logging.warn='logging_log warn'
alias logging.info='logging_log info'
alias logging.debug='logging_log debug'
# log without printing extrainfo (respects 'commands_level')
alias logging.plain='logging_echo'
# print files, heredocs etc, uses cat internally (respects 'commands_level')
alias logging.cat='logging_cat'
# endregion
# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
