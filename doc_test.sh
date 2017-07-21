#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "$(readlink --canonicalize "${BASH_SOURCE[0]}")")/core.sh"

core.import logging
core.import ui
core.import exceptions
core.import utils
core.import arguments
core.import time
core.import documentation
core.import utils
# region doc
# shellcheck disable=SC2034,SC2016
doc_test__doc__='
    The doc_test module implements function and module level testing via "doc
    strings".

    Tests can be run by invoking `doc_test.sh file1 folder1 file2 ...`.

    #### Options:
    ```
    --help|-h                   Print help message.
    --side-by-side              Print diff of failing tests side by side.
    --no-check-namespace        Do not warn about unprefixed definitions.
    --no-check-undocumented     Do not warn about undocumented functions.
    --use-nounset               Accessing undefined variables produces error.
    --verbose|-v                Be more verbose
    ```

    #### Example output `./doc_test.sh -v arguments.sh`
    ```bash
    [verbose:doc_test.sh:330] arguments:[PASS]
    [verbose:doc_test.sh:330] arguments_get_flag:[PASS]
    [verbose:doc_test.sh:330] arguments_get_keyword:[PASS]
    [verbose:doc_test.sh:330] arguments_get_parameter:[PASS]
    [verbose:doc_test.sh:330] arguments_get_positional:[PASS]
    [verbose:doc_test.sh:330] arguments_set:[PASS]
    [info:doc_test.sh:590] arguments - passed 6/6 tests in 918 ms
    [info:doc_test.sh:643] Total: passed 1/1 modules in 941 ms
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

    +documentation_exclude_print
    #### Tests

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
    >>> [ -z "${testing:-}" ] && echo empty
    empty

    Syntax error in testcode:
    >>> f() {a}
    +doc_test_contains
    +doc_test_ellipsis
    syntax error near unexpected token `{a}
    ...

    -documentation_exclude_print
'
# endregion
doc_test_compare_result() {
    # shellcheck disable=SC2034,SC2016
    local __doc__='
    >>> local buffer="line 1
    >>> line 2"
    >>> local got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> local buffer="line 1
    >>> foo"
    >>> local got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    1
    >>> local buffer="+doc_test_contains
    >>> line
    >>> line"
    >>> local got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> local buffer="+doc_test_contains
    >>> line
    >>> foo"
    >>> local got="line 1
    >>> line 2"
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    1
    >>> local buffer="+doc_test_ellipsis
    >>> line
    >>> ...
    >>> "
    >>> local got="line
    >>> line 2
    >>> "
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> local buffer="+doc_test_ellipsis
    >>> line
    >>> ...
    >>> line 2
    >>> "
    >>> local got="line
    >>> ignore
    >>> ignore
    >>> line 2
    >>> "
    >>> doc_test_compare_result "$buffer" "$got"; echo $?
    0
    >>> local buffer="+doc_test_ellipsis
    >>> line
    >>> ...
    >>> line 2
    >>> "
    >>> local got="line
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
        if [[ "$buffer_line" == "+doc_test_no_capture_stderr"* ]]; then
            continue
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
    local __doc__='
    >>> local test_buffer="
    >>> echo foo
    >>> echo bar
    >>> "
    >>> local output_buffer="foo
    >>> bar"
    >>> doc_test_use_side_by_side_output=false
    >>> doc_test_module_under_test=core
    >>> doc_test_nounset=false
    >>> doc_test_eval "$test_buffer" "$output_buffer"
    '
    local test_buffer="$1"
    [[ -z "$test_buffer" ]] && return 0
    local output_buffer="$2"
    local text_buffer="${3-}"
    local module="${4-}"
    local function="${5-}"
    local result=0
    local got declarations_before declarations_after
    doc_test_eval_with_check() {
        local test_buffer="$1"
        local module="$2"
        local function="$3"
        local core_path="$(core_abs_path "$(dirname "${BASH_SOURCE[0]}")")/core.sh"
        local setup_identifier="${module//[^[:alnum:]_]/_}"__doc_test_setup__
        local setup_string="${!setup_identifier:-}"
        test_script="$(
            echo '[ -z "$BASH_REMATCH" ] && BASH_REMATCH=""'
            echo "source $core_path"
            # Suppress the warnings here because they have been already been
            # printed when analyzing the whole module
            echo "core.import $doc_test_module_under_test true"
            echo "$setup_string"
            # _ can be used as anonymous variable (without warning)
            echo '_=""'
            echo "core.get_all_declared_names > $declarations_before"
            $doc_test_nounset && echo 'set -o nounset'
            # wrap in a function so the "local" keyword has an effect inside
            # tests
            echo "
                _() {
                    $test_buffer
                }
                _
            "
            echo "core.get_all_declared_names > $declarations_after"
        )"
        # run in clean environment
        if echo "$output_buffer" | grep '+doc_test_no_capture_stderr' &>/dev/null;
        then
            #(eval "$test_script")
            bash --noprofile --norc <(echo "$test_script")
        else
            #(eval "$test_script" 2>&1)
            bash --noprofile --norc 2>&1 <(echo "$test_script")
        fi
        local result=$?
        return $result
    }
    declarations_before="$(mktemp --suffix=rebash-doc_test)"
    trap "rm -f $declarations_before; exit" EXIT
    declarations_after="$(mktemp --suffix=rebash-doc_test)"
    trap "rm -f $declarations_after; exit" EXIT
    # TODO $module $function as parameters
    got="$(doc_test_eval_with_check "$test_buffer" "$module" "$function")"
    doc_test_declarations_diff="$(diff "$declarations_before" "$declarations_after" \
        | grep -e "^>" | sed 's/^> //')"
    # TODO $module $function as parameters
    doc_test_print_declaration_warning "$module" "$function"
    rm "$declarations_before"
    rm "$declarations_after"
    if ! doc_test_compare_result "$output_buffer" "$got"; then
        echo -e "${ui_color_lightred}test:${ui_color_default}"
        echo "$test_buffer"
        if $doc_test_use_side_by_side_output; then
            output_buffer="expected"$'\n'"${output_buffer}"
            got="got"$'\n'"${got}"
            # TODO exclude doc_test_options
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
    local module="$2"
    local function="$3"
    local test_name="$module"
    [[ -z "$function" ]] || test_name="$function"
    if doc_test_parse_doc_string "$doc_string" doc_test_eval ">>>" \
        "$module" "$function"
    then
        logging.verbose "$test_name:[${ui_color_lightgreen}PASS${ui_color_default}]"
    else
        logging.warn "$test_name:[${ui_color_lightred}FAIL${ui_color_default}]"
        return 1
    fi
}
doc_test_parse_doc_string() {
    local __doc__='
    >>> local doc_string="
    >>>     (test)block
    >>>     output block
    >>> "
    >>> _() {
    >>>     local output_buffer="$2"
    >>>     echo block:
    >>>     while read -r line; do
    >>>         if [ -z "$line" ]; then
    >>>             echo "empty_line"
    >>>         else
    >>>             echo "$line"
    >>>         fi
    >>>     done <<< "$output_buffer"
    >>> }
    >>> doc_test_parse_doc_string "$doc_string" _ "(test)"
    block:
    output block

    >>> local doc_string="
    >>>     Some text (block 1).
    >>>
    >>>
    >>>     Some more text (block 1).
    >>>     (test)block 2
    >>>     (test)block 2.2
    >>>     output block 2
    >>>     (test)block 3
    >>>     output block 3
    >>>
    >>>     Even more text (block 4).
    >>> "
    >>> local i=0
    >>> _() {
    >>>     local test_buffer="$1"
    >>>     local output_buffer="$2"
    >>>     local text_buffer="$3"
    >>>     local line
    >>>     (( i++ ))
    >>>     echo "text_buffer (block $i):"
    >>>     if [ ! -z "$text_buffer" ]; then
    >>>         while read -r line; do
    >>>             if [ -z "$line" ]; then
    >>>                 echo "empty_line"
    >>>             else
    >>>                 echo "$line"
    >>>             fi
    >>>         done <<< "$text_buffer"
    >>>     fi
    >>>     echo "test_buffer (block $i):"
    >>>     [ ! -z "$test_buffer" ] && echo "$test_buffer"
    >>>     echo "output_buffer (block $i):"
    >>>     [ ! -z "$output_buffer" ] && echo "$output_buffer"
    >>>     return 0
    >>> }
    >>> doc_test_parse_doc_string "$doc_string" _ "(test)"
    text_buffer (block 1):
    Some text (block 1).
    empty_line
    empty_line
    Some more text (block 1).
    test_buffer (block 1):
    output_buffer (block 1):
    text_buffer (block 2):
    test_buffer (block 2):
    block 2
    block 2.2
    output_buffer (block 2):
    output block 2
    text_buffer (block 3):
    test_buffer (block 3):
    block 3
    output_buffer (block 3):
    output block 3
    text_buffer (block 4):
    Even more text (block 4).
    test_buffer (block 4):
    output_buffer (block 4):

    '
    local preserve_prompt
    arguments.set "$@"
    arguments.get_flag --preserve-prompt preserve_prompt
    arguments.apply_new_arguments
    local doc_string="$1"  # the docstring to test
    local parse_buffers_function="$2"
    local prompt="$3"
    local module="${4:-}"
    local function="${5:-}"
    [ -z "$prompt" ] && prompt=">>>"
    local text_buffer=""
    local test_buffer=""
    local output_buffer=""

    # remove leading blank line
    [[ "$(head --lines=1 <<< "$doc_string")" != *[![:space:]]* ]] &&
        doc_string="$(tail --lines=+2 <<< "$doc_string" )"
    # remove trailing blank line
    [[ "$(tail --lines=1 <<< "$doc_string")" != *[![:space:]]* ]] &&
        doc_string="$(head --lines=-1 <<< "$doc_string" )"

    doc_test_eval_buffers() {
        $parse_buffers_function "$test_buffer" "$output_buffer" \
            "$text_buffer" "$module" "$function"
        local result=$?
        # clear buffers
        text_buffer=""
        test_buffer=""
        output_buffer=""
        return $result
    }
    local line
    local state=TEXT
    local next_state
    local temp_prompt
    #local indentation=""
    while read -r line; do
        #line="$(echo "$line" | sed -e 's/^[[:blank:]]*//')" # lstrip
        case "$state" in
            TEXT)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    [ ! -z "$text_buffer" ] && text_buffer+=$'\n'"$line"
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    [ ! -z "$text_buffer" ] && doc_test_eval_buffers
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    test_buffer="${line#$prompt}"
                    $preserve_prompt && prompt="$temp_prompt"
                else
                    next_state=TEXT
                    # check if start of text
                    if [ -z "$text_buffer" ]; then
                        text_buffer="$line"
                    else
                        text_buffer+=$'\n'"$line"
                    fi
                fi
                ;;
            TEST)
                #[ -z "$indentation" ] &&
                    #indentation="$(echo "$line"| grep -o "^[[:blank:]]*")"
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    doc_test_eval_buffers
                    [ $? == 1 ] && return 1
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    # check if start of test
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    if [ -z "$test_buffer" ]; then
                        test_buffer="${line#$prompt}"
                    else
                        test_buffer+=$'\n'"${line#$prompt}"
                    fi
                    $preserve_prompt && prompt="$temp_prompt"
                else
                    next_state=OUTPUT
                    output_buffer="$line"
                fi
                ;;
            OUTPUT)
                if [[ "$line" = "" ]]; then
                    next_state=TEXT
                    doc_test_eval_buffers
                    [ $? == 1 ] && return 1
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    doc_test_eval_buffers
                    [ $? == 1 ] && return 1
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    if [ -z "$test_buffer" ]; then
                        test_buffer="${line#$prompt}"
                    else
                        test_buffer+=$'\n'"${line#$prompt}"
                    fi
                    $preserve_prompt && prompt="$temp_prompt"
                else
                    next_state=OUTPUT
                    # check if start of output
                    if [ -z "$output_buffer" ]; then
                        output_buffer="$line"
                    else
                        output_buffer+=$'\n'"$line"
                    fi
                fi
                ;;
        esac
        state=$next_state
    done <<< "$doc_string"
    # shellcheck disable=SC2154
    [[ "$(tail --lines=1 <<< "$text_buffer")" = "" ]] &&
        text_buffer="$(head --lines=-1 <<< "$text_buffer" )"
    doc_test_eval_buffers
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
    [[ "$doc_test_declarations_diff" == "" ]] && return
    core.unique <<< "$doc_test_declarations_diff" \
        | while read -r variable_or_function
    do
        if ! [[ "$variable_or_function" =~ ^${module}[._]* ]]; then
            logging.warn "Test '$test_name' defines unprefixed" \
                "name: '$variable_or_function'"
        fi
    done
}
doc_test_exceptions_active=false
doc_test_test_module() {
    (
    module=$1
    core.import "$module" "$doc_test_supress_declaration"
    doc_test_module_under_test="$(core.abs_path "$module")"
    declared_functions="$core_declared_functions_after_import"
    module="$(basename "$module")"
    module="${module%.sh}"
    declared_module_functions="$(! declare -F | cut -d' ' -f3 | grep -e "^${module%.sh}" )"
    declared_functions="$declared_functions"$'\n'"$declared_module_functions"
    declared_functions="$(core.unique <(echo "$declared_functions"))"

    local total=0
    local success=0
    time.timer_start
    # module level tests
    test_identifier="${module//[^[:alnum:]_]/_}"__doc__
    doc_string="${!test_identifier}"
    if ! [ -z "$doc_string" ]; then
        let "total++"
        doc_test_run_test "$doc_string" "$module" && let "success++"
    fi
    # function level tests
    # TODO detect and warn doc_strings with double quotes
    test_identifier=__doc__
    for fun in $declared_functions; do
        # shellcheck disable=SC2089
        doc_string="$(doc_test_get_function_docstring "$fun")"
        if [[ "$doc_string" != "" ]]; then
            let "total++"
            doc_test_run_test "$doc_string" "$module" "$fun" && let "success++"
        else
            ! $doc_test_supress_undocumented && \
                logging.warn "undocumented function $fun"
        fi
    done
    logging.info "$module - passed $success/$total tests in" \
        "$(time.timer_get_elapsed) ms"
    (( success != total )) && exit 1
    exit 0
    )
}
doc_test_parse_args() {
    local __doc__='
        +documentation_exclude
        >>> doc_test_parse_args non_existing_module
        >>> echo $?
        +doc_test_contains
        +doc_test_ellipsis
        Failed to test file: non_existing_module
        ...
        1

        -documentation_exclude
    '
    local filename module directory verbose help
    arguments.set "$@"
    arguments.get_flag --help -h help
    $help && documentation.print_doc_string "$doc_test__doc__" && return 0
    arguments.get_flag --side-by-side doc_test_use_side_by_side_output
    # do not warn about unprefixed names
    arguments.get_flag --no-check-namespace doc_test_supress_declaration
    # do not warn about undocumented functions
    arguments.get_flag --no-check-undocumented doc_test_supress_undocumented
    # use set -o nounset inside tests
    arguments.get_flag --use-nounset doc_test_nounset
    arguments.get_flag --verbose -v verbose
    arguments.apply_new_arguments

    if $verbose; then
        logging.set_level verbose
    else
        logging.set_level info
    fi
    doc_test_test_directory() {
        directory="$(core.abs_path "$1")"
        for filename in "$directory"/*.sh; do
            let "total++"
            doc_test_test_module "$(core.abs_path "$filename")" &
        done
    }
    time.timer_start
    local total=0
    local success=0
    if [ $# -eq 0 ] || [ "$@" == "" ];then
        doc_test_test_directory "$(dirname "$0")"
    else
        for filename in "$@"; do
            if [ -f "$filename" ]; then
                let "total++"
                doc_test_test_module "$(core.abs_path "$filename")" &
            elif [ -d "$filename" ]; then
                doc_test_test_directory "$filename"
            else
                let "total++"
                logging.warn "Failed to test file: $filename"
            fi
        done
    fi
    local job
    for job in $(jobs -p); do
        wait "$job" && let "success++"
    done
    logging.info "Total: passed $success/$total modules in" \
        "$(time.timer_get_elapsed) ms"
    (( success != total )) && return 1
    return 0
}

if core.is_main; then
    doc_test_parse_args "$@"
fi
# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
