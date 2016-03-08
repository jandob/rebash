#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

core.import logging
core.import ui
# shellcheck disable=SC2034,SC2016
doc_test__doc__='
    Tests are delimited by blank lines:
    >>> echo bar
    bar

    >>> echo $(( 1 + 2 ))
    3

    But can also occur right after another:
    >>> echo foo
    foo
    >>> echo bar
    bar

    Single quotes can be escaped like so:
    >>> echo '"'"'$foos'"'"'
    $foos

    Or so
    >>> echo '\''$foos'\''
    $foos

    Some text in between.

    Return values can not be used directly:
    >>> bad() { return 1; }
    >>> bad || echo good
    good

    Multiline output
    >>> for i in 1 2; do
    >>>     echo $i;
    >>> done
    1
    2

    Ellipsis support
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +doc_test_ellipsis
    1
    2
    ...

    Ellipsis are non greedy
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +doc_test_ellipsis
    1
    ...
    4
    5

    Each testcase has its own scope:
    >>> testing="foo"; echo $testing
    foo
    >>> [ -z "$testing" ] && echo empty
    empty

    Syntax error in testcode:
    >>> f() {a}
    +doc_test_contains
    +doc_test_ellipsis
    syntax error near unexpected token `{a}
    ...
'
doc_test_compare_result() {
    # shellcheck disable=SC2034,SC2016
    local __doc__='
    >>> buffer="line 1
    >>> line 2"
    >>> got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> buffer="line 1
    >>> foo"
    >>> got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    1
    >>> buffer="+doc_test_contains
    >>> line
    >>> line"
    >>> got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> buffer="+doc_test_contains
    >>> line
    >>> foo"
    >>> got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    1
    >>> buffer="+doc_test_ellipsis
    >>> line
    >>> ...
    >>> "
    >>> got="line
    >>> line 2
    >>> "
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> buffer="+doc_test_ellipsis
    >>> line
    >>> ...
    >>> line 2
    >>> "
    >>> got="line
    >>> ignore
    >>> ignore
    >>> line 2
    >>> "
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> buffer="+doc_test_ellipsis
    >>> line
    >>> ...
    >>> line 2
    >>> "
    >>> got="line
    >>> ignore
    >>> ignore
    >>> line 2
    >>> line 3
    >>> "
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    1
    '
    local buffer="$1"
    local got="$2"
    local buffer_line
    local got_line
    compare_lines () {
        if $doc_test_contains; then
            [[ "$got_line" == *"$buffer_line"* ]] || return 1
        else
            [[ "$buffer_line" == "$got_line" ]] || return 1
        fi
    }
    local result=0
    local doc_test_contains=false
    local doc_test_ellipsis=false
    local doc_test_ellipsis_on=false
    local doc_test_ellipsis_waiting=false
    local end_of_buffer=false
    local end_of_got=false
    while true; do
        # parse buffer line
        if ! $doc_test_ellipsis_waiting && ! $end_of_buffer && ! read -r -u3 buffer_line; then
            end_of_buffer=true
        fi
        if [[ "$buffer_line" == "+doc_test_contains"* ]]; then
            doc_test_contains=true
            continue
        fi
        if [[ "$buffer_line" == "+doc_test_ellipsis"* ]]; then
            doc_test_ellipsis=true
            continue
        fi

        # parse got line
        if $end_of_got || ! read -r -u4 got_line; then
            end_of_got=true
        fi

        # set result
        if $doc_test_ellipsis;then
            if [[ "$buffer_line" == "..." ]]; then
                doc_test_ellipsis_on=true
            else
                [[ "$buffer_line" != "" ]] && $doc_test_ellipsis_on && doc_test_ellipsis_waiting=true
            fi
        fi
        $end_of_buffer && $end_of_got && break
        $end_of_buffer && $doc_test_ellipsis_waiting && result=1 && break
        $end_of_got && $doc_test_ellipsis_waiting && result=1 && break
        $end_of_buffer && $doc_test_ellipsis_on && break
        if $doc_test_ellipsis_on; then
            if compare_lines; then
                doc_test_ellipsis_on=false
                doc_test_ellipsis_waiting=false
            else
                $end_of_got && result=1
            fi
        else
            compare_lines || result=1
        fi

    done 3<<< "$buffer" 4<<< "$got"
    return $result
}
doc_test_capture_stderr=true
# shellcheck disable=SC2154
doc_test_eval() {
    local buffer="$1"
    #logging.debug buffer: "$buffer" 1>&2
    local output_buffer="$2"
    #logging.debug output_buffer: "$output_buffer" 1>&2
    local result=0
    local got
    # NOTE: capture_stderr can currently only be used before tests run. E.g. in
    # the test setup function. TODO document this option
    if $doc_test_capture_stderr; then
        got=$'\n'"$(eval "$buffer" 2>&1; exit $?)"
    else
        got=$'\n'"$(eval "$buffer"; exit $?)"
    fi
    #logging.debug got:"$?" "$got" 1>&2
    if ! doc_test_compare_result "$output_buffer" "$got"; then
        echo -e "[${ui_color_lightred}FAIL${ui_color_default}]"
        echo -e "${ui_color_lightred}test:${ui_color_default}"\
            "$buffer"
        echo -e "${ui_color_lightred}expected:${ui_color_default}"\
            "$output_buffer"
        echo -e "${ui_color_lightred}got:${ui_color_default}"\
            "$got"
        return 1
    fi
}
doc_test_run_test() {
    #TODO add indentation support (in output_buffer)
    local teststring="$1"  # the docstring to test
    local prompt=">>>"
    local buffer=""  # content of buffer gets evaled
    local output_buffer=""

    eval_buffers() {
        doc_test_eval "$buffer" "$output_buffer"
        local result=$?
        buffer=""  # clear buffer
        output_buffer=""  # clear buffer
        return $result
    }
    local line
    local state=TEXT
    local next_state
    while read -r line; do
        #TODO indentation support
        local indentation=$(echo -e "$line"| grep -o "^[[:space:]]*")
        line="$(echo -e "$line" | sed -e 's/^[[:space:]]*//')" # lstrip
        case "$state" in
            TEXT)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                elif [[ "$line" = ">>>"* ]]; then
                    next_state=TEST
                    buffer="${buffer}"$'\n'"${line#$prompt}"
                else
                    next_state=TEXT
                fi
                ;;
            TEST)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    eval_buffers
                    [ $? == 1 ] && return
                elif [[ "$line" = ">>>"* ]];then
                    next_state=TEST
                    buffer="${buffer}"$'\n'"${line#$prompt}"
                else
                    next_state=OUTPUT
                    output_buffer="${output_buffer}"$'\n'"${line}"
                fi
                ;;
            OUTPUT)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    eval_buffers
                    [ $? == 1 ] && return
                elif [[ "$line" = ">>>"* ]];then
                    next_state=TEST
                    eval_buffers
                    [ $? == 1 ] && return
                    buffer="${buffer}"$'\n'"${line#$prompt}"
                else
                    next_state=OUTPUT
                    output_buffer="${output_buffer}"$'\n'"${line}"
                fi
                ;;
        esac
        state=$next_state
    done <<< "$teststring"
    # shellcheck disable=SC2154
    eval_buffers
    [ $? == 1 ] && return
    # shellcheck disable=SC2154
    echo -e "[${ui_color_lightgreen}PASS${ui_color_default}]"
}
doc_test_doc_identifier=__doc__
doc_test_doc_regex="/__doc__='/,/';/p"
doc_test_get_function_docstring() {
    (
        unset $doc_test_doc_identifier
        eval "$(type "$fun" | sed -n "$doc_test_doc_regex")"
        echo "${!doc_test_doc_identifier}"
    )
}
doc_test_test_module() {
    # TODO prefix all variables starting here
    (
    module=$1
    core.import "$module"
    module="$(basename "$module")"
    module="${module%.sh}"

    # test setup
    setup_identifier="$module"__doc_test_setup__
    teststring="${!setup_identifier}"
    if ! [ -z "$teststring" ]; then
        eval "$teststring"
    fi

    # module level tests
    (
        test_identifier="$module"__doc__
        teststring="${!test_identifier}"
        if ! [ -z "$teststring" ]; then
            result=$(doc_test_run_test "$teststring")
            old_level="$(logging.get_level)"
            logging.set_level info
            logging.info "$module":"$result"
            logging.set_level "$old_level"
        fi
    )
    # function level tests
    test_identifier=__doc__
    for fun in $(! declare -F | cut -d' ' -f3 | grep -e "^${module%.sh}" ); do
        # don't test this function (prevent funny things from happening)
        if [ "$fun" == "${FUNCNAME[0]}" ]; then
            continue
        fi
        # shellcheck disable=SC2089
        regex="/__doc__='/,/';/p"
        teststring=$(
            unset $test_identifier
            eval "$(type "$fun" | sed -n "$regex")"
            echo "${!test_identifier}"
        )
        [ -z "$teststring" ] && continue
        result=$(doc_test_run_test "$teststring")
        old_level="$(logging.get_level)"
        logging.set_level info
        logging.info "$fun":"$result"
        logging.set_level "$old_level"
    done
    )
}
doc_test_parse_args() {
    local filename
    local module
    if [ $# -eq 0 ]; then
        for filename in $(dirname "$0")/*.sh; do
            module=$(basename "${filename%.sh}")
            doc_test_test_module "$module"
        done
    else
        for module in "$@"; do
            doc_test_test_module "$(core_abs_path $module)"
        done
    fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    doc_test_parse_args "$@"
fi
