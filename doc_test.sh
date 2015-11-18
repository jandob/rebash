
function hans() {
    local __test__="
    hans
    >>>2
    "
    echo $(( 1+1 ))
}
function hans2() {
    local __test__="
    hans2 bla
    >>>bla
    hans2 blabla
    >>>blabla
    "
    echo $1
}
function run_test() {
    buffer=""
    for line in $1; do
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')" # lstrip
        if [[ "$line" =~ '>>>' ]]; then
            if [[ ">>>$buffer" == "$line" ]]; then
                echo PASS
            else
                echo FAIL:
                echo expected: ">>>$buffer"
                echo got: "$line"
            fi
        else
            buffer="$(eval "$line")"
        fi
    done
}
function parse_test_strings() {
    local IFS_saved=$IFS
    IFS=$'\n'
    for fun in $(declare -F | cut -d' ' -f3); do
        # don't test this function (prevent funny things from happening)
        if [ $fun == $FUNCNAME ]; then
            continue
        fi
        local teststring=$(
            eval "$(type $fun | sed -n '/__test__="/,/"/p')"
            echo "$__test__"
        )
        echo testing $fun
        run_test "$teststring"
    done
    IFS=$IFS_saved
}
parse_test_strings
