#!/usr/bin/bash
source $(dirname $0)/core.sh
core.check_namespace doc_test
core.import ui
core.import logging
core.import utils

#parse_test_strings


doc_test._run_test() {
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
                echo -e "[$ui_powerline_ok]"
            else
                echo -e "[$ui_powerline_fail]"
                echo \texpected: ">>>$buffer"
                echo \tgot: "$line"
            fi
        else
            buffer="$(eval "$line")"
        fi
    done
    local IFS=$IFS_saved
}
doc_test._test_module() {
    local module=$1
    logging.info testing module \"$module\"
    core.import $module
    for fun in $(declare -F | cut -d' ' -f3 | grep -e "^$module" ); do
        # don't test this function (prevent funny things from happening)
        if [ $fun == $FUNCNAME ]; then
            continue
        fi
        local teststring=$(
            local regex="/__test__='/,/'/p"
            eval "$(type $fun | sed -n $regex)"
            echo "$__test__"
        )
        [ -z "$teststring" ] && continue
        local result=$(doc_test._run_test "$teststring")
        echo "$fun": "$result"
    done
}
doc_test._test_module $1
