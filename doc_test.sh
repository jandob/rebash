#!/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

core.import logging
core.import ui

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
    '
    local buffer="$1"
    local got="$2"
    local buffer_line
    local got_line
    local result=0
    local doc_test_contains=false
    local doc_test_ellipsis=false
    while true; do
        read -u3 buffer_line || break
        if [[ "$buffer_line" == "+doc_test_contains"* ]]; then
            doc_test_contains=true
            continue
        fi
        if [[ "$buffer_line" == "+doc_test_ellipsis"* ]]; then
            doc_test_ellipsis=true
            continue
        fi
        read -u4 got_line
        if $doc_test_ellipsis && [[ "$buffer_line" == "..." ]]; then
            continue
        fi
        # compare the lines
        if $doc_test_contains; then
            [[ "$got_line" == *"$buffer_line"* ]] || result=1
        else
            [[ "$buffer_line" == "$got_line" ]] || result=1
        fi
    done 3<<< "$buffer" 4<<< "$got"
    return $result
}
doc_test_eval() {
    local buffer="$1"
    #logging.debug buffer: "$buffer" 1>&2
    local output_buffer="$2"
    #logging.debug output_buffer: "$output_buffer" 1>&2
    local result=0
    local got=$'\n'"$(eval "$buffer" 2>&1; exit $?)"
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
    #TODO add indentation support
    local teststring="$1"  # the docstring to test
    local prompt=">>>"
    local buffer=""  # content of buffer gets evaled
    local output_buffer=""
    local inside_test=false
    local inside_result=false
    reset_buffers() {
        inside_result=false
        inside_test=false
        buffer=""  # clear buffer
        output_buffer=""  # clear buffer
    }
    local line
    while read line; do
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')" # lstrip
        if [[ "$line" = "" ]]; then
            if $inside_test ; then
                doc_test_eval "$buffer" "$output_buffer"
                if [ $? == 1 ]; then return; fi
            fi
            reset_buffers
        elif [[ "$line" = ">>>"* ]]; then # put into buffer
            if $inside_result; then
                doc_test_eval "$buffer" "$output_buffer"
                if [ $? == 1 ]; then return; fi
                reset_buffers
            fi
            inside_test=true
            buffer="${buffer}"$'\n'"${line#>>>}"
        else
            $inside_test && inside_result=true
            output_buffer="${output_buffer}"$'\n'"${line}"
            ! $inside_test && ! $inside_result && reset_buffers
        fi
    done <<< "$teststring"
    $inside_result && ! doc_test_eval "$buffer" "$output_buffer" && return
    echo -e "[${ui_color_lightgreen}PASS${ui_color_default}]"
}
doc_test_test_module() {
    local module=$1
    (
    # module level tests
    core.import "$module"
    test_identifier="$module"__doc__
    teststring="${!test_identifier}"
    if ! [ -z "$teststring" ]; then
        result=$(doc_test_run_test "$teststring")
        logging.info "$module":"$result"
    fi
    # function level tests
    test_identifier=__doc__
    for fun in $(declare -F | cut -d' ' -f3 | grep -e "^${module%.sh}" ); do
        # don't test this function (prevent funny things from happening)
        if [ $fun == $FUNCNAME ]; then
            continue
        fi
        regex="/__doc__='/,/';/p"
        teststring=$(
            unset $test_identifier
            eval "$(type $fun | sed -n $regex)"
            echo "${!test_identifier}"
        )
        [ -z "$teststring" ] && continue
        result=$(doc_test_run_test "$teststring")
        logging.info "$fun":"$result"
    done
    )
}
doc_test_parse_args() {
    if [ $# -eq 0 ]; then
        local filename
        for filename in $(dirname $0)/*.sh; do
            local module=$(basename ${filename%.sh})
            doc_test_test_module $module
        done
    else
        local module
        for module in $@; do
            doc_test_test_module ${module%.sh}
        done
    fi
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    logging.set_level debug
    logging.set_commands_level info
    doc_test_parse_args "$@"
fi
