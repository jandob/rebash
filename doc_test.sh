#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/core.sh"

core.import logging
core.import ui
core.import exceptions
core.import utils
core.import arguments
# region doc
# shellcheck disable=SC2034,SC2016
doc_test__doc__='
    The doc_test module implements function and module level testing via "doc
    strings".

    Tests can be run by invoking `doc_test.sh file1 folder1 file2 ...`.

    #### Example output
    ```bash
    [info:doc_test.sh:433] arguments_get_flag:[PASS]
    [info:doc_test.sh:433] arguments_get_keyword:[PASS]
    [info:doc_test.sh:433] arguments_get_parameter:[PASS]
    [info:doc_test.sh:433] arguments_set:[PASS]
    ```

    A doc string can be defined for a function by defining a variable named
    `__doc__` at the function scope.
    On the module level, the variable name should be `<module_name>__doc__`
    (e.g. `arguments__doc__` for the example above).
    Note: The doc string needs to be defined with single quotes.

    Code contained in a module level variable named
    `<module_name>__doc_test_setup__` will be run once before all the Tests of
    a module are run. This is usefull for defining mockup functions/data
    that can be used throughout all tests.

    #### Tests
    +documentation_toggle_section_start

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

    Multiline output
    >>> local i
    >>> for i in 1 2; do
    >>>     echo $i;
    >>> done
    1
    2

    Ellipsis support
    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +doc_test_ellipsis
    1
    2
    ...

    Ellipsis are non greedy
    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +doc_test_ellipsis
    1
    ...
    4
    5

    Each testcase has its own scope:
    >>> local testing="foo"; echo $testing
    foo
    >>> [ -z "$testing" ] && echo empty
    empty

    Syntax error in testcode:
    >>> f() {a}
    +doc_test_contains
    +doc_test_ellipsis
    syntax error near unexpected token `{a}
    ...

    +documentation_toggle_section_end
'
# endregion
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
    doc_test_compare_lines () {
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
            if doc_test_compare_lines; then
                doc_test_ellipsis_on=false
                doc_test_ellipsis_waiting=false
            else
                $end_of_got && result=1
            fi
        else
            doc_test_compare_lines || result=1
        fi

    done 3<<< "$buffer" 4<<< "$got"
    return $result
}
# shellcheck disable=SC2154
doc_test_eval() {
    local buffer="$1"
    [[ -z "$buffer" ]] && return 0
    #logging.debug buffer: "$buffer" 1>&2
    local output_buffer="$2"
    #logging.debug output_buffer: "$output_buffer" 1>&2
    local result=0
    local got declarations_before declarations_after
    eval_function_wrapper() {
        # wrap eval in a function so the "local" keyword has an effect inside
        # tests
        $doc_test_exceptions_active && exceptions.activate
        eval "$@"
        $doc_test_exceptions_active && exceptions.deactivate
    }
    eval_with_check() {
        (
            core.get_all_declared_names > "$declarations_before"
            eval_function_wrapper "$@"
            result=$?
            core.get_all_declared_names > "$declarations_after"
            exit $result
        )
    }
    eval_function=eval
    $doc_test_strict_declaration_check && eval_function=eval_with_check
    $doc_test_strict_declaration_check && \
        declarations_before="$(mktemp --suffix=rebash-doc_test)"
    $doc_test_strict_declaration_check && \
        declarations_after="$(mktemp --suffix=rebash-doc_test)"
    if $doc_test_capture_stderr; then
        got="$($eval_function "$buffer" 2>&1; exit $?)"
    else
        got="$($eval_function "$buffer"; exit $?)"
    fi
    $doc_test_strict_declaration_check && \
        diff "$declarations_before" "$declarations_after" \
        | grep -e "^>" | sed 's/^> //' >> "$doc_test_declaration_diff"
    $doc_test_strict_declaration_check && rm "$declarations_before"
    $doc_test_strict_declaration_check && rm "$declarations_after"

    #logging.debug got:"$?" "$got" 1>&2
    if ! doc_test_compare_result "$output_buffer" "$got"; then
        echo -e "[${ui_color_lightred}FAIL${ui_color_default}]"
        echo -e "${ui_color_lightred}test:${ui_color_default}"
        echo "$buffer"
        if $doc_test_use_side_by_side_output; then
            output_buffer="${ui_color_lightred}expected${ui_color_default}"$'\n'"${output_buffer}"
            got="${ui_color_lightred}got${ui_color_default}"$'\n'"${got}"
            local diff=diff
            utils.dependency_check colordiff && diff=colordiff
            $diff --side-by-side <(echo "$output_buffer") <(echo "$got")
        else
            echo -e "${ui_color_lightred}expected:${ui_color_default}"
            echo "$output_buffer"
            echo -e "${ui_color_lightred}got:${ui_color_default}"
            echo "$got"
        fi
        return 1
    fi
}
doc_test_run_test() {
    local doc_string="$1"
    doc_test_parse_doc_string "$doc_string" doc_test_eval ">>>"
    if [[ $? == 0 ]]; then
        # shellcheck disable=SC2154
        echo -e "[${ui_color_lightgreen}PASS${ui_color_default}]"
    fi
}
doc_test_parse_doc_string() {
    #TODO add indentation support (in output_buffer)
    local doc_string="$1"  # the docstring to test
    local parse_buffers_function="$2"
    local prompt="$3"
    local text_buffer=""
    local buffer=""
    local output_buffer=""

    eval_buffers() {
        buffer="$(strip_empty_lines <<< "$buffer")"
        output_buffer="$(strip_empty_lines <<< "$output_buffer")"
        $parse_buffers_function "$buffer" "$output_buffer" "$text_buffer"
        local result=$?
        # clear buffers
        text_buffer=""
        buffer=""
        output_buffer=""
        return $result
    }
    strip_empty_lines() {
        local line
        while read -r line; do
            [[ "${line}" != *[^[:space:]]* ]] && continue
            echo "$line"
        done
    }
    local line
    local state=TEXT
    local next_state
    while read -r line; do
        #TODO indentation support
        local indentation=$(echo "$line"| grep -o "^[[:space:]]*")
        line="$(echo "$line" | sed -e 's/^[[:space:]]*//')" # lstrip
        case "$state" in
            TEXT)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    text_buffer="${text_buffer}"$'\n'
                elif [[ "$line" = ">>>"* ]]; then
                    next_state=TEST
                    buffer="${buffer}"$'\n'"${line#$prompt}"
                else
                    next_state=TEXT
                    text_buffer="${text_buffer}"$'\n'"${line}"
                fi
                ;;
            TEST)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    eval_buffers
                    [ $? == 1 ] && return 1
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
                    [ $? == 1 ] && return 1
                elif [[ "$line" = ">>>"* ]];then
                    next_state=TEST
                    eval_buffers
                    [ $? == 1 ] && return 1
                    buffer="${buffer}"$'\n'"${line#$prompt}"
                else
                    next_state=OUTPUT
                    output_buffer="${output_buffer}"$'\n'"${line}"
                fi
                ;;
        esac
        state=$next_state
    done <<< "$doc_string"
    # shellcheck disable=SC2154
    eval_buffers
}
doc_test_doc_identifier=__doc__
doc_test_doc_regex="/__doc__='/,/';$/p"
doc_test_doc_regex_one_line="__doc__='.*';$"
doc_test_get_function_docstring() {
    function="$1"
    (
        unset $doc_test_doc_identifier
        if ! doc_string="$(type "$function" | \
            grep "$doc_test_doc_regex_one_line")"
        then
            doc_string="$(type "$function" | sed --quiet "$doc_test_doc_regex")"
        fi
        eval "$doc_string"
        echo "${!doc_test_doc_identifier}"
    )
}
doc_test_print_declaration_warning() {
    local module="$1"
    local function="$2"
    local test_name="$module"
    [[ -z "$function" ]] || test_name="$function"
    core.unique "$doc_test_declaration_diff" | while read -r variable_or_function
    do
        if ! [[ $variable_or_function =~ ^${module}[._]* ]]; then
            logging.warn "Test '$test_name' defines unprefixed" \
                "name: '$variable_or_function'"
        fi
    done
}
doc_test_exceptions_active=false
doc_test_test_module() {
    (
    _="" # can be used as anonymous variable without warning inside tests
    module=$1
    core.import "$module" "$doc_test_check_namespace"
    declared_functions="$core_declared_functions_after_import"
    module="$(basename "$module")"
    module="${module%.sh}"
    declared_module_functions="$(! declare -F | cut -d' ' -f3 | grep -e "^${module%.sh}" )"
    declared_functions="$declared_functions"$'\n'"$declared_module_functions"
    declared_functions="$(core.unique <(echo "$declared_functions"))"

    # test setup
    ## NOTE: capture_stderr and strict_declaration_check can currently only be
    ## used before tests run. E.g. in the test setup function. TODO document
    ## these options
    doc_test_capture_stderr=true
    doc_test_strict_declaration_check=true

    setup_identifier="${module//[^[:alnum:]_]/_}"__doc_test_setup__
    doc_string="${!setup_identifier}"
    if ! [ -z "$doc_string" ]; then
        eval "$doc_string"
    fi
    if "$exceptions_active"; then
        doc_test_exceptions_active=true
        exceptions.deactivate
    fi

    # module level tests
    (
        test_identifier="${module//[^[:alnum:]_]/_}"__doc__
        doc_string="${!test_identifier}"
        if ! [ -z "$doc_string" ]; then
            $doc_test_strict_declaration_check && \
                doc_test_declaration_diff="$(mktemp --suffix=rebash-doc_test)"
            result=$(doc_test_run_test "$doc_string")
            old_level="$(logging.get_level)"
            logging.set_level info
            $doc_test_strict_declaration_check && \
                doc_test_print_declaration_warning "$module"
            logging.info "$module":"$result"
            logging.set_level "$old_level"
            $doc_test_strict_declaration_check && \
                rm "$doc_test_declaration_diff"
        fi
    )
    # function level tests
    test_identifier=__doc__
    for fun in $declared_functions; do
        # shellcheck disable=SC2089
        doc_string="$(doc_test_get_function_docstring "$fun")"
        [ -z "$doc_string" ] && continue
        $doc_test_strict_declaration_check && \
            doc_test_declaration_diff="$(mktemp --suffix=rebash-doc_test)"
        result=$(doc_test_run_test "$doc_string")
        old_level="$(logging.get_level)"
        logging.set_level info
        $doc_test_strict_declaration_check && \
            doc_test_print_declaration_warning "$module" "$fun"
        logging.info "$fun":"$result"
        logging.set_level "$old_level"
        $doc_test_strict_declaration_check && \
            rm "$doc_test_declaration_diff"
    done
    )
}
doc_test_parse_args() {
    local filename
    local module
    local directory
    arguments.set "$@"
    arguments.get_flag --side-by-side doc_test_use_side_by_side_output
    arguments.get_flag --no-check-namespace doc_test_check_namespace
    doc_test_check_namespace="$($doc_test_check_namespace || echo true)"
    set -- "${arguments_new_arguments[@]}"
    test_directory() {
        directory="$(core.abs_path "$1")"
        for filename in "$directory"/*.sh; do
            doc_test_test_module "$(core.abs_path "$filename")"
        done
    }
    if [ $# -eq 0 ];then
        test_directory "$(dirname "$0")"
    else
        for filename in "$@"; do
            if [ -f "$filename" ]; then
                doc_test_test_module "$(core.abs_path "$filename")"
            elif [ -d "$filename" ]; then
                test_directory "$filename"
            else
                old_level="$(logging.get_level)"
                logging.set_level info
                logging.warn "Failed to test file: $filename"
                logging.set_level "$old_level"
            fi
        done
    fi
}

if core.is_main; then
    doc_test_parse_args "$@"
fi
# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
