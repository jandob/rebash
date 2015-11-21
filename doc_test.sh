#!/usr/bin/sh
source $(dirname $0)/core.sh
core.check_namespace doc_test
core.import ui
core.import logging
core.import utils

doc_test_run_test() {
    local teststring="$1"
    local buffer=""
    local IFS_saved=$IFS
    IFS=$'\n'
    for line in $teststring; do
        #TODO handle empty lines
        #echo line: "$line" >/dev/stderr
        # [[ "$line" =~ '\s *' ]] && echo HANS >/dev/stderr
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')" # lstrip
        if [[ "$line" =~ '>>>' ]]; then
            if [[ ">>>$buffer" == "$line" ]]; then
                echo -e "[${ui_color_lightgreen}PASS${ui_color_default}]"
            else
                echo -e "[${ui_color_lightred}FAIL${ui_color_default}]"
                echo -e "\texpected: >>>$buffer"
                echo -e "\tgot: $line"
            fi
        else
            buffer="$(eval "$line")"
        fi
    done
    local IFS=$IFS_saved
}
doc_test_test_module() {
    local module=$1
    logging.info "testing module \"$module\""
    core.import $module
    local fun
    for fun in $(declare -F | cut -d' ' -f3 | grep -e "^$module" ); do
        # don't test this function (prevent funny things from happening)
        if [ $fun == $FUNCNAME ]; then
            continue
        fi
        local regex="/__test__='/,/'/p"
        local teststring=$(
            unset __test__
            local regex="/__test__='/,/'/p"
            eval "$(type $fun | sed -n $regex)"
            echo "$__test__"
        )
        [ -z "$teststring" ] && continue
        local result=$(doc_test_run_test "$teststring")
        logging.info "$fun": "$result"
        exit 0
    done
}
doc_test_parse_args() {
    if [ $# -eq 0 ]; then
        local filename
        for filename in $(dirname $0)/*; do
            local module=$(basename ${filename%.sh})
            doc_test_test_module $module
        done
    else
        local module
        for module in $@; do
            doc_test_test_module $module
        done
    fi
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    logging.set_log_level info
    logging.set_commands_log_level info
    doc_test_parse_args "$@"
fi
