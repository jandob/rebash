# ReBash - bash/shell library/framework
## Features
- import system
- advanced logging (colors, control stdout/stderr, log levels, ...)
- error handling
- doc testing
- (TODO) argument parser
- (TODO) documentation helpers

## Usage
```
#!/usr/bin/env bash
source path/to/core.sh
core.import <modulename>
core.import <another modulename>
# use modules ...
```

## Module Overview
### core
- import other modules

### logging
TODO

### ui
variables for printing in color and unicode glyphs
- features are detected automatically, but can also be enabled/disabled manually

### doctest
TODO

### exceptions
TODO
# Generated documentation
## Documentation for module array

### Documentation for function array_filter
```

>>>a=(one two three wolf)
>>>b=( $(array_filter ".*wo.*" ${a[@]}) )
>>>echo ${b[*]}

two wolf
```
### Documentation for function array_get_index

Get index of value in an array
```

>>>a=(one two three)
>>>array_get_index one ${a[@]}

0
```
```

>>>a=(one two three)
>>>array_get_index bar foo bar baz

1
```
## Documentation for module change_root

## Documentation for module core

### Documentation for function core_is_defined

Tests if variable is defined (can alo be empty)
```

>>> foo="bar"
>>> core_is_defined foo; echo $?
>>> [[ -v foo ]]; echo $?

0
0
```
```

>>> defined_but_empty=""
>>> core_is_defined defined_but_empty; echo $?

0
```
```

>>> core_is_defined undefined_variable; echo $?

1
```
```

>>> set -u
>>> core_is_defined undefined_variable; echo $?

1
```

Same Tests for bash < 4.2
```

>>> core__bash_version_test=true
>>> foo="bar"
>>> core_is_defined foo; echo $?

0
```
```

>>> core__bash_version_test=true
>>> defined_but_empty=""
>>> core_is_defined defined_but_empty; echo $?

0
```
```

>>> core__bash_version_test=true
>>> core_is_defined undefined_variable; echo $?

1
```
```

>>> core__bash_version_test=true
>>> set -u
>>> core_is_defined undefined_variable; echo $?

1
```
### Documentation for function core_is_empty

Tests if variable is empty (undefined variables are not empty)
```

>>> foo="bar"
>>> core_is_empty foo; echo $?

1
```
```

>>> defined_and_empty=""
>>> core_is_empty defined_and_empty; echo $?

0
```
```

>>> core_is_empty undefined_variable; echo $?

1
```
```

>>> set -u
>>> core_is_empty undefined_variable; echo $?

1
```
### Documentation for function core_rel_path

Stolen from http://stackoverflow.com/a/12498485/31038
```

>>> core_rel_path "/A/B/C" "/A"

../..
```
```

>>> core_rel_path "/A/B/C" "/A/B"

..
```
```

>>> core_rel_path "/A/B/C" "/A/B/C"

```
```

>>> core_rel_path "/A/B/C" "/A/B/C/D"

D
```
```

>>> core_rel_path "/A/B/C" "/A/B/C/D/E"

D/E
```
```

>>> core_rel_path "/A/B/C" "/A/B/D"

../D
```
```

>>> core_rel_path "/A/B/C" "/A/B/D/E"

../D/E
```
```

>>> core_rel_path "/A/B/C" "/A/D"

../../D
```
```

>>> core_rel_path "/A/B/C" "/A/D/E"

../../D/E
```
```

>>> core_rel_path "/A/B/C" "/D/E/F"

../../../D/E/F
```
## Documentation for module dictionary

### Documentation for function dictionary_get

Usage:
variable=$(dictionary.get dictionary_name key)
Examples:
```

>>> dictionary_get unset_map unset_value
>>> dictionary_get unset_map unset_value; echo $?

1
```
```

>>> dictionary__bash_version_test=true
>>> dictionary_get unset_map unset_value; echo $?

1
```
```

>>> dictionary_set map foo 2
>>> dictionary_set map bar 1
>>> dictionary_get map foo
>>> dictionary_get map bar

2
1
```
```

>>> dictionary_set map foo "a b c"
>>> dictionary_get map foo

a b c
```
```

>>> dictionary__bash_version_test=true
>>> dictionary_set map foo 2
>>> dictionary_get map foo

2
```
```

>>> dictionary__bash_version_test=true
>>> dictionary_set map foo "a b c"
>>> dictionary_get map foo

a b c
```
### Documentation for function dictionary_get_keys
```

>>> dictionary_set map foo "a b c" bar 5
>>> dictionary_get_keys map

bar
foo
```
```

>>> dictionary__bash_version_test=true
>>> dictionary_set map foo "a b c" bar 5
>>> dictionary_get_keys map | sort -u

bar
foo
```
### Documentation for function dictionary_set

Usage:
dictionary.set dictionary_name key value
Tests:
```

>>> dictionary_set map foo 2
>>> echo ${dictionary__store_map[foo]}

2
```
```

>>> dictionary_set map foo "a b c" bar 5
>>> echo ${dictionary__store_map[foo]}
>>> echo ${dictionary__store_map[bar]}

a b c
5
```
```

>>> dictionary_set map foo "a b c" bar; echo $?

1
```
```

>>> dictionary__bash_version_test=true
>>> dictionary_set map foo 2
>>> echo $dictionary__store_map_foo

2
```
```

>>> dictionary__bash_version_test=true
>>> dictionary_set map foo "a b c"
>>> echo $dictionary__store_map_foo

a b c
```
## Documentation for module doc_test

Tests are delimited by blank lines:
```

>>> echo bar

bar
```
```

>>> echo $(( 1 + 2 ))

3
```

But can also occur right after another:
```

>>> echo foo

foo
```
```

>>> echo bar

bar
```

Single quotes can be escaped like so:
```

>>> echo '$foos'

$foos
```

Or so
```

>>> echo '$foos'

$foos
```

Some text in between.
Return values can not be used directly:
```

>>> bad() { return 1; }
>>> bad || echo good

good
```

Multiline output
```

>>> for i in 1 2; do
>>>     echo $i;
>>> done

1
2
```

Ellipsis support
```

>>> for i in 1 2 3 4 5; do
>>>     echo $i;
>>> done

+doc_test_ellipsis
1
2
...
```

Ellipsis are non greedy
```

>>> for i in 1 2 3 4 5; do
>>>     echo $i;
>>> done

+doc_test_ellipsis
1
...
4
5
```

Each testcase has its own scope:
```

>>> testing="foo"; echo $testing

foo
```
```

>>> [ -z "$testing" ] && echo empty

empty
```

Syntax error in testcode:
```

>>> f() {a}

+doc_test_contains
+doc_test_ellipsis
syntax error near unexpected token `{a}
...
```
### Documentation for function doc_test_compare_result
```

>>> buffer="line 1
>>> line 2"
>>> got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?

0
```
```

>>> buffer="line 1
>>> foo"
>>> got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?

1
```
```

>>> buffer="+doc_test_contains
>>> line
>>> line"
>>> got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?

0
```
```

>>> buffer="+doc_test_contains
>>> line
>>> foo"
>>> got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?

1
```
```

>>> buffer="+doc_test_ellipsis
>>> line
>>> ...
>>> "
>>> got="line
>>> line 2
>>> "
>>> doc_test_compare_result "$buffer" "$got"; echo $?

0
```
```

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
```
```

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
```
## Documentation for module documentation

## Documentation for module exceptions

NOTE: The try block is executed in a subshell, so no outer variables can be
assigned.
```

>>> exceptions.activate
>>> false

+doc_test_ellipsis
Traceback (most recent call first):
...
```
```

>>> exceptions_activate
>>> exceptions.try {
>>>     false
>>> } exceptions.catch {
>>>     echo caught
>>> }

caught
```

Exceptions in a subshell:
```

>>> exceptions_activate
>>> ( false )

+doc_test_ellipsis
Traceback (most recent call first):
...
Traceback (most recent call first):
...
```
```

>>> exceptions_activate
>>> exceptions.try {
>>>     (false; echo "this should not be printed")
>>>     echo "this should not be printed"
>>> } exceptions.catch {
>>>     echo caught
>>> }

+doc_test_ellipsis
caught
```

Nested exceptions:
```

>>> foo() {
>>>     true
>>>     exceptions.try {
>>>         false
>>>     } exceptions.catch {
>>>         echo caught inside foo
>>>     }
>>>     false # this is cought at top level
>>>     echo this should never be printed
>>> }
>>>
>>> exceptions.try {
>>>     foo
>>> } exceptions.catch {
>>>     echo caught
>>> }
>>>

caught inside foo
caught
```

Exceptions are implicitely active inside try blocks:
```

>>> foo() {
>>>     echo $1
>>>     true
>>>     exceptions.try {
>>>         false
>>>     } exceptions.catch {
>>>         echo caught inside foo
>>>     }
>>>     false # this is not caught
>>>     echo this should never be printed
>>> }
>>>
>>> foo "EXCEPTIONS NOT ACTIVE:"
>>> exceptions_activate
>>> foo "EXCEPTIONS ACTIVE:"

+doc_test_ellipsis
EXCEPTIONS NOT ACTIVE:
caught inside foo
this should never be printed
EXCEPTIONS ACTIVE:
caught inside foo
Traceback (most recent call first):
...
```

Exceptions inside conditionals:
```

>>> exceptions_activate
>>> false && echo "should not be printed"
>>> (false) && echo "should not be printed"
>>> exceptions.try {
>>>     (
>>>     false
>>>     echo "should not be printed"
>>>     )
>>> } exceptions.catch {
>>>     echo caught
>>> }

caught
```
### Documentation for function exceptions_deactivate
```

>>> trap 'echo $foo' ERR
>>> exceptions.activate
>>> trap -p ERR | cut --delimiter "'" --fields 2
>>> exceptions.deactivate
>>> trap -p ERR | cut --delimiter "'" --fields 2

exceptions_error_handler
echo $foo
```
## Documentation for module logging

The standard loglevel is critical
```

>>> logging.get_level
>>> logging.get_commands_level

critical
critical
```
```

>>> logging.error error-message
>>> logging.critical critical-message
>>> logging.warn warn-message
>>> logging.info info-message
>>> logging.debug debug-message

+doc_test_contains
error-message
critical-message
```

If the output of commands should be printed, the commands_level needs to be
greater than or equal to the log_level.
```

>>> logging.set_level critical
>>> logging.set_commands_level debug
>>> echo foo

```
```

>>> logging.set_level info
>>> logging.set_commands_level info
>>> echo foo

foo
```

Another logging prefix can be set by overriding "logging_get_prefix".
```

>>> logging_get_prefix() {
>>>     local level=$1
>>>     local path="${BASH_SOURCE[2]##./}"
>>>     path=$(basename "$path")
>>>     echo "[myprefix - ${level}:${path}]"
>>> }
>>> logging.critical foo

[myprefix - critical:doc_test.sh] foo
```

"logging.plain" can be used to print at any log level and without the
prefix.
```

>>> logging.set_level critical
>>> logging.set_commands_level debug
>>> logging.plain foo

foo
```

"logging.cat" can be used to print files (e.g "logging.cat < file.txt")
or heredocs. Like "logging.plain", it also prints at any log level and
without the prefix.
```

>>> echo foo | logging.cat

foo
```
### Documentation for function logging_set_level
```

>>> logging.set_commands_level info
>>> logging.set_level info
>>> echo $logging_level
>>> echo $logging_commands_level

3
3
```
## Documentation for module ui

## Documentation for module utils

### Documentation for function utils_dependency_check

This function check if all given dependencies are present.
Examples:
```

>>> utils_dependency_check mkdir ls; echo $?

0
```
```

>>> utils_dependency_check mkdir __not_existing__ 1>/dev/null; echo $?

2
```
```

>>> utils_dependency_check __not_existing__ 1>/dev/null; echo $?

2
```
```

>>> utils_dependency_check "ls __not_existing__"; echo $?

__not_existing__
2
```
### Documentation for function utils_dependency_check_pkgconfig

This function check if all given libraries can be found.
Examples:
```

>>> utils_dependency_check_shared_library libc.so; echo $?

0
```
```

>>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?

2
```
```

>>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?

2
```
### Documentation for function utils_dependency_check_shared_library

This function check if all given shared libraries can be found.
Examples:
```

>>> utils_dependency_check_shared_library libc.so; echo $?

0
```
```

>>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?

2
```
```

>>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?

2
```
### Documentation for function utils_find_block_device
```

>>> lsblk() {
>>>     if [[ "${@: -1}" == "" ]];then
>>>         echo "lsblk: : not a block device"
>>>         return 1
>>>     fi
>>>     if [[ "${@: -1}" != "/dev/sdb" ]];then
>>>         echo "/dev/sda disk"
>>>         echo "/dev/sda1 part SYSTEM_LABEL 0x7"
>>>         echo "/dev/sda2 part"
>>>     fi
>>>     if [[ "${@: -1}" != "/dev/sda" ]];then
>>>         echo "/dev/sdb disk"
>>>         echo "/dev/sdb1 part boot_partition "
>>>         echo "/dev/sdb2 part system_partition"
>>>     fi
>>> }
>>> blkid() {
>>>     [[ "${@: -1}" != "/dev/sda2" ]] && return 0
>>>     echo "gpt"
>>>     echo "only discoverable by blkid"
>>>     echo "boot_partition"
>>>     echo "192d8b9e"
>>> }
>>> utils_find_block_device "boot_partition"
>>> utils_find_block_device "boot_partition" /dev/sda
>>> utils_find_block_device "discoverable by blkid"
>>> utils_find_block_device "_partition"
>>> utils_find_block_device "not matching anything" || echo not found
>>> utils_find_block_device "" || echo not found

/dev/sdb1
/dev/sda2
/dev/sda2
/dev/sdb1 /dev/sdb2
not found
not found
```
