# ReBash - bash/shell library/framework
## Features
- modular import system
- advanced logging (colors, control stdout/stderr, log levels, ...)
- error handling (exceptions, try-catch)
- doc testing inspired by python
- documentation generation
- (TODO) argument parser

## Usage
```
#!/usr/bin/env bash
source path/to/core.sh
core.import <modulename>
core.import <another modulename>
# use modules ...
```

## Module Overview
- [core](#module-core)
- [logging](#module-logging)
- [ui](#module-ui)
- [exceptions](#module-exceptions)
- [doc_test](#module-doc_test)
- [documentation](#module-documentation)
- [array](#module-array)
- [arguments](#module-arguments)

# Generated documentation
## Module arguments
### Function arguments_get_flag

```
arguments.get_flag flag [flag_aliases...] variable_name
```
Sets `variable_name` to true if flag (or on of its aliases) is contained in
the argument array (see `arguments.set`)
**Example**
`arguments.get_flag verbose --verbose -v verbose_is_set`
**Tests**
```
>>> arguments.set other_param1 --foo other_param2
>>> local foo bar
>>> arguments.get_flag --foo -f foo
>>> echo $foo
>>> arguments.get_flag --bar bar
>>> echo $bar
>>> echo "${arguments_new_arguments[@]}"
true
false
other_param1 other_param2
```
```
>>> arguments.set -f
>>> local foo
>>> arguments.get_flag --foo -f foo
>>> echo $foo
true
```
### Function arguments_get_keyword

```
arguments.get_keyword keyword variable_name
```
Sets `variable_name` to the "value" of `keyword` the argument array (see
`arguments.set`) contains "keyword=value".
**Example**
`arguments.get_keyword log loglevel`
**Tests**
```
>>> local foo
>>> arguments.set other_param1 foo=bar baz=baz other_param2
>>> arguments.get_keyword foo foo
>>> echo $foo
>>> echo "${arguments_new_arguments[@]}"
bar
other_param1 baz=baz other_param2
```
### Function arguments_get_parameter

```
arguments.get_parameter parameter [parameter_aliases...] variable_name
```
Sets `variable_name` to the field following `parameter` (or one of the
`parameter_aliases`) from the argument array (see `arguments.set`).
**Example**
`arguments.get_parameter --log-level -l loglevel`
**Tests**
```
>>> local foo
>>> arguments.set other_param1 --foo bar other_param2
>>> arguments.get_parameter --foo -f foo
>>> echo $foo
>>> echo "${arguments_new_arguments[@]}"
bar
other_param1 other_param2
```
### Function arguments_set

```
arguments.set argument1 argument2 ...
```
Set the array the arguments-module is working on. After getting the desired
arguments, the new argument array can be accessed via
`arguments_new_arguments`. This new array contains all remaining arguments.
## Module array
### Function array_filter

Filters values from given array by given regular expression.
```
>>> local a=(one two three wolf)
>>> local b=( $(array.filter ".*wo.*" "${a[@]}") )
>>> echo ${b[*]}
two wolf
```
### Function array_get_index

Get index of value in an array
```
>>> local a=(one two three)
>>> array_get_index one "${a[@]}"
0
```
```
>>> local a=(one two three)
>>> array_get_index two "${a[@]}"
1
```
```
>>> array_get_index bar foo bar baz
1
```
### Function array_slice

Returns a slice of an array (similar to Python).
From the Python documentation:
One way to remember how slices work is to think of the indices as pointing
between elements, with the left edge of the first character numbered 0.
Then the right edge of the last element of an array of length n has
index n, for example:
+---+---+---+---+---+---+
| 0 | 1 | 2 | 3 | 4 | 5 |
+---+---+---+---+---+---+
0   1   2   3   4   5   6
-6  -5  -4  -3  -2  -1
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 1:-2 "${a[@]}")
1 2 3
```
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 0:1 "${a[@]}")
0
```
```
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice 1:1 "${a[@]}")" ] && echo empty
empty
```
```
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice 2:1 "${a[@]}")" ] && echo empty
empty
```
```
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice -2:-3 "${a[@]}")" ] && echo empty
empty
```
```
>>> [ -z "$(array.slice -2:-2 "${a[@]}")" ] && echo empty
empty
```

Slice indices have useful defaults; an omitted first index defaults to
zero, an omitted second index defaults to the size of the string being
sliced.
```
>>> local a=(0 1 2 3 4 5)
>>> # from the beginning to position 2 (excluded)
>>> echo $(array.slice 0:2 "${a[@]}")
>>> echo $(array.slice :2 "${a[@]}")
0 1
0 1
```
```
>>> local a=(0 1 2 3 4 5)
>>> # from position 3 (included) to the end
>>> echo $(array.slice 3:"${#a[@]}" "${a[@]}")
>>> echo $(array.slice 3: "${a[@]}")
3 4 5
3 4 5
```
```
>>> local a=(0 1 2 3 4 5)
>>> # from the second-last (included) to the end
>>> echo $(array.slice -2:"${#a[@]}" "${a[@]}")
>>> echo $(array.slice -2: "${a[@]}")
4 5
4 5
```
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice -4:-2 "${a[@]}")
2 3
```

If no range is given, it works like normal array indices.
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice -1 "${a[@]}")
5
```
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice -2 "${a[@]}")
4
```
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 0 "${a[@]}")
0
```
```
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 1 "${a[@]}")
1
```
```
>>> local a=(0 1 2 3 4 5)
>>> array.slice 6 "${a[@]}"; echo $?
1
```
```
>>> local a=(0 1 2 3 4 5)
>>> array.slice -7 "${a[@]}"; echo $?
1
```
## Module change_root
### Function change_root

This function performs a linux change root if needed and provides all
kernel api filesystems in target root by using a change root interface
with minimal needed rights.
Examples:
`change_root /new_root /usr/bin/env bash some arguments`
### Function change_root_with_fake_fallback

Perform the available change root program wich needs at least rights.
Examples:
`change_root_with_fake_fallback /new_root /usr/bin/env bash some arguments`
### Function change_root_with_kernel_api

Performs a change root by mounting needed host locations in change root
environment.
Examples:
`change_root_with_kernel_api /new_root /usr/bin/env bash some arguments`
## Module core
### Function core_get_all_declared_names

Return all declared variables and function in the current
scope.
E.g.
`declarations="$(core.get_all_declared_names)"`
### Function core_import
```
>>> (core.import ./test/mockup_module-b.sh)
imported module c
warn: module "mockup_module_c" defines unprefixed name: "foo123"
imported module b
```

Modules should be imported only once.
```
>>> (core.import ./test/mockup_module_a.sh && \
>>>     core.import ./test/../test/mockup_module_a.sh)
imported module a
```
```
>>> (
>>> core.import exceptions
>>> exceptions.activate
>>> core.import utils
>>> )

```
### Function core_is_defined

Tests if variable is defined (can alo be empty)
```
>>> local foo="bar"
>>> core_is_defined foo; echo $?
>>> [[ -v foo ]]; echo $?
0
0
```
```
>>> local defined_but_empty=""
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
>>> local foo="bar"
>>> core_is_defined foo; echo $?
0
```
```
>>> core__bash_version_test=true
>>> local defined_but_empty=""
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
### Function core_is_empty

Tests if variable is empty (undefined variables are not empty)
```
>>> local foo="bar"
>>> core_is_empty foo; echo $?
1
```
```
>>> local defined_and_empty=""
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
### Function core_is_main

Returns true if current script is being executed.
```
>>> core.is_main && echo yes
yes
```
### Function core_rel_path

Computes relative path from $1 to $2.
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
.
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
### Function core_unique
```
>>> local foo="a
b
a
b
c
b
c"
>>> echo -e "$foo" | core.unique
a
b
c
```
## Module dictionary
### Function dictionary_get

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
### Function dictionary_get_keys
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
### Function dictionary_set

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
## Module doc_test

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
Multiline output
```
>>> local i
>>> for i in 1 2; do
>>>     echo $i;
>>> done
1
2
```

Ellipsis support
```
>>> local i
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
>>> local i
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
>>> local testing="foo"; echo $testing
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
### Function doc_test_compare_result
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
## Module documentation
## Module exceptions

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
>>> exceptions_foo() {
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
>>>     exceptions_foo
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
### Function exceptions_deactivate
```
>>> set -o errtrace
>>> trap 'echo $foo' ERR
>>> exceptions.activate
>>> trap -p ERR | cut --delimiter "'" --fields 2
>>> exceptions.deactivate
>>> trap -p ERR | cut --delimiter "'" --fields 2
exceptions_error_handler
echo $foo
```
## Module logging

The available log levels are:
error critical warn info debug
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
### Function logging_set_level
```
>>> logging.set_commands_level info
>>> logging.set_level info
>>> echo $logging_level
>>> echo $logging_commands_level
3
3
```
## Module ui

This module provides variables for printing colorful and unicode glyphs.
The Terminal features are detected automatically but can also be
enabled/disabled manually (see
[ui.enable_color](#function-ui_enable_color) and
[ui.enable_unicode_glyphs](#function-ui_enable_unicode_glyphs)).
### Function ui_disable_color

Disables color output explicitly.
```
>>> ui.enable_color
>>> ui.disable_color
>>> echo -E "$ui_color_red" red "$ui_color_default"
red
```
### Function ui_disable_unicode_glyphs

Disables unicode glyphs explicitly.
```
>>> ui.enable_unicode_glyphs
>>> ui.disable_unicode_glyphs
>>> echo -E "$ui_powerline_ok"
+
```
### Function ui_enable_color

Enables color output explicitly.
```
>>> ui.disable_color
>>> ui.enable_color
>>> echo -E $ui_color_red red $ui_color_default
[0;31m red [0m
```
### Function ui_enable_unicode_glyphs

Enables unicode glyphs explicitly.
```
>>> ui.disable_unicode_glyphs
>>> ui.enable_unicode_glyphs
>>> echo -E "$ui_powerline_ok"
✔
```
## Module utils
### Function utils_dependency_check

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
### Function utils_dependency_check_pkgconfig

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
### Function utils_dependency_check_shared_library

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
### Function utils_find_block_device
```
>>> utils_find_block_device "boot_partition"
/dev/sdb1
```
```
>>> utils_find_block_device "boot_partition" /dev/sda
/dev/sda2
```
```
>>> utils_find_block_device "discoverable by blkid"
/dev/sda2
```
```
>>> utils_find_block_device "_partition"
/dev/sdb1 /dev/sdb2
```
```
>>> utils_find_block_device "not matching anything" || echo not found
not found
```
```
>>> utils_find_block_device "" || echo not found
not found
```
