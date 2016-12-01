# ReBash - bash/shell library/framework

[![Build Status](https://travis-ci.org/jandob/rebash.svg?branch=master)](https://travis-ci.org/jandob/rebash)

## Motivation
Developing in bash has some serious flaws:

- scoping - bash functions are always global
- no exception handling
- larger projects quickly become non-transparent
- ...

## Features
- modular import system
- advanced logging (colors, control stdout/stderr, log levels, ...)
- error handling (exceptions, try-catch)
- doc testing inspired by python
- documentation generation
- argument parser
- utility functions

## Doc test examples

`./doc_test.sh array.sh -v`

![Gif of doc_test run on the array module](images/doc_test_array_fail.gif)

`./doc_test.sh `

![Gif of full doc_test run](images/doc_test_full.gif)

`./doc_test.sh -v`

![Gif of full verbose doc_test run with failure](images/doc_test_full_verbose_fail.gif)

## Usage
Source the [core](#module-core) module and use `core.import` to import
other modules.
``` bash
#!/usr/bin/env bash
source path/to/core.sh
core.import <modulename>
core.import <another modulename>
# use modules ...
```

## Installation
Currently only an archlinux package is available at the
[aur](https://aur.archlinux.org/packages/rebash/).
After installation all rebash files are available under `/usr/lib/rebash/`.
The doc_test and documentation modules are available as
`/usr/bin/rebash-doc-test` and `/usr/bin/rebash-documentation`.

## Module Concept
Modules are single files. The function [core.import](#function-core_import)
guarantees that each module is sourced only once.
All variables and functions defined inside a module should be prefixed with the
module name. E.g. `core_import` for the function `import` in module `core`.
Aliases inside the module are used to define public functions and to have a
convinient way to distinguish the module namespace from the function
(`alias core.import="core_import"`).

A typical minimal module looks like this (with filename `mockup.sh`):
``` bash
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
core.import logging
mockup_foo() {
    echo foo
}
alias mockup.foo="mockup_foo"
```

## Best practices / coding style
### No surprises
Loading modules (i.e. when sourced by the import mechanism) should be
side-effect free, so only variable and function definitions should be made at
the module level.
If the module should be executable, use [core.is_main](#function-core_is_main).
For example this module does activate exceptions only when run directly, not
when being sourced.
``` bash
#!/usr/bin/env bash
source path/to/core.sh
core.import exceptions
main() {
    exceptions.activate
    # do stuff
}
if core.is_main; then
    main
fi
```

### Testing
Write [doc_tests](#module-doc_test) for every module and function.
Write the tests before writing the implementation.

### Linting with shellcheck
Use [shellcheck](http://www.shellcheck.net/) to tackle common errors and
pitfalls in bash.

# Generated documentation
## Module arguments
The arguments module provides an argument parser that can be used in
functions and scripts.

Different functions are provided in order to parse an arguments array.

#### Example
```bash
>>> _() {
>>>     local value
>>>     arguments.set "$@"
>>>     arguments.get_parameter param1 value
>>>     echo "param1: $value"
>>>     arguments.get_keyword keyword2 value
>>>     echo "keyword2: $value"
>>>     arguments.get_flag --flag4 value
>>>     echo "--flag4: $value"
>>>     # NOTE: Get the positionals last
>>>     arguments.get_positional 1 value
>>>     echo 1: "$value"
>>>     # Alternative way to get positionals: Set the arguments array to
>>>     # $arguments_new_arguments
>>>     set -- "${arguments_new_arguments[@]}"
>>>     echo 1: "$1"
>>> }
>>> _ param1 value1 keyword2=value2 positional3 --flag4
param1: value1
keyword2: value2
--flag4: true
1: positional3
1: positional3
```
### Function arguments_get_flag
```
arguments.get_flag flag [flag_aliases...] variable_name
```

Sets `variable_name` to true if flag (or on of its aliases) is contained in
the argument array (see `arguments.set`)

#### Example
```
arguments.get_flag verbose --verbose -v verbose_is_set
```

#### Tests
```bash
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
```bash
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

#### Example
```
arguments.get_keyword log loglevel
```
#### Tests
```bash
>>> local foo
>>> arguments.set other_param1 foo=bar baz=baz other_param2
>>> arguments.get_keyword foo foo
>>> echo $foo
>>> echo "${arguments_new_arguments[@]}"
bar
other_param1 baz=baz other_param2
```
```bash
>>> local foo
>>> arguments.set other_param1 foo=bar baz=baz other_param2
>>> arguments.get_keyword foo
>>> echo $foo
>>> arguments.get_keyword baz foo
>>> echo $foo
bar
baz
```
### Function arguments_get_parameter
```
arguments.get_parameter parameter [parameter_aliases...] variable_name
```

Sets `variable_name` to the field following `parameter` (or one of the
`parameter_aliases`) from the argument array (see `arguments.set`).

#### Example
```
arguments.get_parameter --log-level -l loglevel
```

#### Tests
```bash
>>> local foo
>>> arguments.set other_param1 --foo bar other_param2
>>> arguments.get_parameter --foo -f foo
>>> echo $foo
>>> echo "${arguments_new_arguments[@]}"
bar
other_param1 other_param2
```
### Function arguments_get_positional
```
arguments.get_positional index variable_name
```

Get the positional parameter at `index`. Use after extracting parameters,
keywords and flags.

```bash
>>> arguments.set parameter foo --flag pos1 pos2 --keyword=foo
>>> arguments.get_flag --flag _
>>> arguments.get_parameter parameter _
>>> arguments.get_keyword --keyword _
>>> local positional1 positional2
>>> arguments.get_positional 1 positional1
>>> arguments.get_positional 2 positional2
>>> echo "$positional1 $positional2"
pos1 pos2
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

```bash
>>> local a=(one two three wolf)
>>> local b=( $(array.filter ".*wo.*" "${a[@]}") )
>>> echo ${b[*]}
two wolf
```
### Function array_get_index
Get index of value in an array

```bash
>>> local a=(one two three)
>>> array_get_index one "${a[@]}"
0
```
```bash
>>> local a=(one two three)
>>> array_get_index two "${a[@]}"
1
```
```bash
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
```
+---+---+---+---+---+---+
| 0 | 1 | 2 | 3 | 4 | 5 |
+---+---+---+---+---+---+
0   1   2   3   4   5   6
-6  -5  -4  -3  -2  -1
```

```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 1:-2 "${a[@]}")
1 2 3
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 0:1 "${a[@]}")
0
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice 1:1 "${a[@]}")" ] && echo empty
empty
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice 2:1 "${a[@]}")" ] && echo empty
empty
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice -2:-3 "${a[@]}")" ] && echo empty
empty
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> [ -z "$(array.slice -2:-2 "${a[@]}")" ] && echo empty
empty
```
Slice indices have useful defaults; an omitted first index defaults to
zero, an omitted second index defaults to the size of the string being
sliced.
```bash
>>> local a=(0 1 2 3 4 5)
>>> # from the beginning to position 2 (excluded)
>>> echo $(array.slice 0:2 "${a[@]}")
>>> echo $(array.slice :2 "${a[@]}")
0 1
0 1
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> # from position 3 (included) to the end
>>> echo $(array.slice 3:"${#a[@]}" "${a[@]}")
>>> echo $(array.slice 3: "${a[@]}")
3 4 5
3 4 5
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> # from the second-last (included) to the end
>>> echo $(array.slice -2:"${#a[@]}" "${a[@]}")
>>> echo $(array.slice -2: "${a[@]}")
4 5
4 5
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice -4:-2 "${a[@]}")
2 3
```
If no range is given, it works like normal array indices.
```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice -1 "${a[@]}")
5
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice -2 "${a[@]}")
4
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 0 "${a[@]}")
0
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> echo $(array.slice 1 "${a[@]}")
1
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> array.slice 6 "${a[@]}"; echo $?
1
```
```bash
>>> local a=(0 1 2 3 4 5)
>>> array.slice -7 "${a[@]}"; echo $?
1
```
## Module change_root
### Function change_root
This function performs a linux change root if needed and provides all
kernel api filesystems in target root by using a change root interface
with minimal needed rights.

#### Example:

`change_root /new_root /usr/bin/env bash some arguments`
### Function change_root_with_fake_fallback
Perform the available change root program wich needs at least rights.

#### Example:

`change_root_with_fake_fallback /new_root /usr/bin/env bash some arguments`
### Function change_root_with_kernel_api
Performs a change root by mounting needed host locations in change root
environment.

#### Example:

`change_root_with_kernel_api /new_root /usr/bin/env bash some arguments`
## Module core
### Function core_get_all_aliases
Returns all defined aliases in the current scope.
### Function core_get_all_declared_names
Return all declared variables and function in the current scope.

E.g.
`declarations="$(core.get_all_declared_names)"`
### Function core_import
IMPORTANT: Do not use core.import inside functions -> aliases do not work
TODO: explain this in more detail

```bash
>>> (
>>> core.import logging
>>> logging_set_level warn
>>> core.import test/mockup_module-b.sh false
>>> )
+doc_test_contains
imported module c
module "mockup_module_c" defines unprefixed name: "foo123"
imported module b
```
Modules should be imported only once.
```bash
>>> (core.import test/mockup_module_a.sh && \
>>>     core.import test/mockup_module_a.sh)
imported module a
```
```bash
>>> (
>>> core.import test/mockup_module_a.sh false
>>> echo $core_declared_functions_after_import
>>> )
imported module a
mockup_module_a_foo
```
```bash
>>> (
>>> core.import logging
>>> logging_set_level warn
>>> core.import test/mockup_module_c.sh false
>>> echo $core_declared_functions_after_import
>>> )
+doc_test_contains
imported module b
imported module c
module "mockup_module_c" defines unprefixed name: "foo123"
foo123
```
### Function core_is_defined
Tests if variable is defined (can also be empty)

```bash
>>> local foo="bar"
>>> core_is_defined foo; echo $?
>>> [[ -v foo ]]; echo $?
0
0
```
```bash
>>> local defined_but_empty=""
>>> core_is_defined defined_but_empty; echo $?
0
```
```bash
>>> core_is_defined undefined_variable; echo $?
1
```
```bash
>>> set -o nounset
>>> core_is_defined undefined_variable; echo $?
1
```
Same Tests for bash < 4.2
```bash
>>> core__bash_version_test=true
>>> local foo="bar"
>>> core_is_defined foo; echo $?
0
```
```bash
>>> core__bash_version_test=true
>>> local defined_but_empty=""
>>> core_is_defined defined_but_empty; echo $?
0
```
```bash
>>> core__bash_version_test=true
>>> core_is_defined undefined_variable; echo $?
1
```
```bash
>>> core__bash_version_test=true
>>> set -o nounset
>>> core_is_defined undefined_variable; echo $?
1
```
### Function core_is_empty
Tests if variable is empty (undefined variables are not empty)

```bash
>>> local foo="bar"
>>> core_is_empty foo; echo $?
1
```
```bash
>>> local defined_and_empty=""
>>> core_is_empty defined_and_empty; echo $?
0
```
```bash
>>> core_is_empty undefined_variable; echo $?
1
```
```bash
>>> set -u
>>> core_is_empty undefined_variable; echo $?
1
```
### Function core_is_main
Returns true if current script is being executed.

```bash
>>> # Note: this test passes because is_main is called by doc_test.sh which
>>> # is being executed.
>>> core.is_main && echo yes
yes
```
### Function core_rel_path
Computes relative path from $1 to $2.
Taken from http://stackoverflow.com/a/12498485/2972353

```bash
>>> core_rel_path "/A/B/C" "/A"
../..
```
```bash
>>> core_rel_path "/A/B/C" "/A/B"
..
```
```bash
>>> core_rel_path "/A/B/C" "/A/B/C/D"
D
```
```bash
>>> core_rel_path "/A/B/C" "/A/B/C/D/E"
D/E
```
```bash
>>> core_rel_path "/A/B/C" "/A/B/D"
../D
```
```bash
>>> core_rel_path "/A/B/C" "/A/B/D/E"
../D/E
```
```bash
>>> core_rel_path "/A/B/C" "/A/D"
../../D
```
```bash
>>> core_rel_path "/A/B/C" "/A/D/E"
../../D/E
```
```bash
>>> core_rel_path "/A/B/C" "/D/E/F"
../../../D/E/F
```
```bash
>>> core_rel_path "/" "/"
.
```
```bash
>>> core_rel_path "/A/B/C" "/A/B/C"
.
```
```bash
>>> core_rel_path "/A/B/C" "/"
../../../
```
### Function core_source_with_namespace_check
Sources a script and checks variable definitions before and after sourcing.
### Function core_unique
```bash
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
Usage: `variable=$(dictionary.get dictionary_name key)`

#### Examples

```bash
>>> dictionary_get unset_map unset_value; echo $?
1
```
```bash
>>> dictionary__bash_version_test=true
>>> dictionary_get unset_map unset_value; echo $?
1
```
```bash
>>> dictionary_set map foo 2
>>> dictionary_set map bar 1
>>> dictionary_get map foo
>>> dictionary_get map bar
2
1
```
```bash
>>> dictionary_set map foo "a b c"
>>> dictionary_get map foo
a b c
```
```bash
>>> dictionary__bash_version_test=true
>>> dictionary_set map foo 2
>>> dictionary_get map foo
2
```
```bash
>>> dictionary__bash_version_test=true
>>> dictionary_set map foo "a b c"
>>> dictionary_get map foo
a b c
```
### Function dictionary_get_keys
```bash
>>> dictionary_set map foo "a b c" bar 5
>>> dictionary_get_keys map
bar
foo
```
```bash
>>> dictionary__bash_version_test=true
>>> dictionary_set map foo "a b c" bar 5
>>> dictionary_get_keys map | sort -u
bar
foo
```
### Function dictionary_set
Usage: `dictionary.set dictionary_name key value`

#### Tests

```bash
>>> dictionary_set map foo 2
>>> echo ${dictionary__store_map[foo]}
2
```
```bash
>>> dictionary_set map foo "a b c" bar 5
>>> echo ${dictionary__store_map[foo]}
>>> echo ${dictionary__store_map[bar]}
a b c
5
```
```bash
>>> dictionary_set map foo "a b c" bar; echo $?
1
```
```bash
>>> dictionary__bash_version_test=true
>>> dictionary_set map foo 2
>>> echo $dictionary__store_map_foo
2
```
```bash
>>> dictionary__bash_version_test=true
>>> dictionary_set map foo "a b c"
>>> echo $dictionary__store_map_foo
a b c
```
## Module doc_test
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

#### Tests

Tests are delimited by blank lines:
```bash
>>> echo bar
bar
```
```bash
>>> echo $(( 1 + 2 ))
3
```
But can also occur right after another:
```bash
>>> echo foo
foo
```
```bash
>>> echo bar
bar
```
Single quotes can be escaped like so:
```bash
>>> echo '$foos'
$foos
```
Or so
```bash
>>> echo '$foos'
$foos
```
Some text in between.

Multiline output
```bash
>>> local i
>>> for i in 1 2; do
>>>     echo $i;
>>> done
1
2
```
Ellipsis support
```bash
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
```bash
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
```bash
>>> local testing="foo"; echo $testing
foo
```
```bash
>>> [ -z "${testing:-}" ] && echo empty
empty
```
Syntax error in testcode:
```bash
>>> f() {a}
+doc_test_contains
+doc_test_ellipsis
syntax error near unexpected token `{a}
...
```
### Function doc_test_compare_result
```bash
>>> local buffer="line 1
>>> line 2"
>>> local got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?
0
```
```bash
>>> local buffer="line 1
>>> foo"
>>> local got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?
1
```
```bash
>>> local buffer="+doc_test_contains
>>> line
>>> line"
>>> local got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?
0
```
```bash
>>> local buffer="+doc_test_contains
>>> line
>>> foo"
>>> local got="line 1
>>> line 2"
>>> doc_test_compare_result "$buffer" "$got"; echo $?
1
```
```bash
>>> local buffer="+doc_test_ellipsis
>>> line
>>> ...
>>> "
>>> local got="line
>>> line 2
>>> "
>>> doc_test_compare_result "$buffer" "$got"; echo $?
0
```
```bash
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
```
```bash
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
```
### Function doc_test_eval
```bash
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

```
### Function doc_test_parse_args

### Function doc_test_parse_doc_string
```bash
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
```
```bash
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
```
## Module documentation
### Function documentation_serve
Serves a readme via webserver. Uses Flatdoc.

```bash
>>> # TODO write test
>>> echo hans
hans
```
## Module exceptions
NOTE: The try block is executed in a subshell, so no outer variables can be
assigned.

```bash
>>> exceptions.activate
>>> false
+doc_test_ellipsis
Traceback (most recent call first):
...
```
```bash
>>> exceptions_activate
>>> exceptions.try {
>>>     false
>>> }; exceptions.catch {
>>>     echo caught
>>> }
caught
```
Exceptions in a subshell:
```bash
>>> exceptions_activate
>>> ( false )
+doc_test_ellipsis
Traceback (most recent call first):
...
Traceback (most recent call first):
...
```
```bash
>>> exceptions_activate
>>> exceptions.try {
>>>     (false; echo "this should not be printed")
>>>     echo "this should not be printed"
>>> }; exceptions.catch {
>>>     echo caught
>>> }
+doc_test_ellipsis
caught
```
Nested exceptions:
```bash
>>> exceptions_foo() {
>>>     true
>>>     exceptions.try {
>>>         false
>>>     }; exceptions.catch {
>>>         echo caught inside foo
>>>     }
>>>     false # this is cought at top level
>>>     echo this should never be printed
>>> }
>>>
>>> exceptions.try {
>>>     exceptions_foo
>>> }; exceptions.catch {
>>>     echo caught
>>> }
>>>
caught inside foo
caught
```
Exceptions are implicitely active inside try blocks:
```bash
>>> foo() {
>>>     echo $1
>>>     true
>>>     exceptions.try {
>>>         false
>>>     }; exceptions.catch {
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
```bash
>>> exceptions_activate
>>> false && echo "should not be printed"
>>> (false) && echo "should not be printed"
>>> exceptions.try {
>>>     (
>>>     false
>>>     echo "should not be printed"
>>>     )
>>> }; exceptions.catch {
>>>     echo caught
>>> }
caught
```
Print a caught exception traceback.
```bash
>>> exceptions.try {
>>>     false
>>> }; exceptions.catch {
>>>     echo caught
>>>     echo "$exceptions_last_traceback"
>>> }
+doc_test_ellipsis
caught
Traceback (most recent call first):
...
```
Different syntax variations are possible.
```bash
>>> exceptions.try {
>>>     ! true
>>> }; exceptions.catch {
>>>     echo caught
>>> }

```
```bash
>>> exceptions.try
>>>     false
>>> exceptions.catch {
>>>     echo caught
>>> }
caught
```
```bash
>>> exceptions.try
>>>     false
>>> exceptions.catch
>>>     echo caught
caught
```
```bash
>>> exceptions.try {
>>>     false
>>> }
>>> exceptions.catch {
>>>     echo caught
>>> }
caught
```
```bash
>>> exceptions.try {
>>>     false
>>> }
>>> exceptions.catch
>>> {
>>>     echo caught
>>> }
caught
```
### Function exceptions_deactivate
```bash
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
```bash
>>> logging.get_level
>>> logging.get_commands_level
critical
critical
```
```bash
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
```bash
>>> logging.set_level critical
>>> logging.set_commands_level debug
>>> echo foo

```
```bash
>>> logging.set_level info
>>> logging.set_commands_level info
>>> echo foo
foo
```
Another logging prefix can be set by overriding "logging_get_prefix".
```bash
>>> logging_get_prefix() {
>>>     local level=$1
>>>     echo "[myprefix - ${level}]"
>>> }
>>> logging.critical foo
[myprefix - critical] foo
```
"logging.plain" can be used to print at any log level and without the
prefix.
```bash
>>> logging.set_level critical
>>> logging.set_commands_level debug
>>> logging.plain foo
foo
```
"logging.cat" can be used to print files (e.g "logging.cat < file.txt")
or heredocs. Like "logging.plain", it also prints at any log level and
without the prefix.
```bash
>>> echo foo | logging.cat
foo
```
### Function logging_plain
```bash
>>> logging.set_level info
>>> logging.set_commands_level debug
>>> logging.debug "not shown"
>>> echo "not shown"
>>> logging.plain "shown"
shown
```
### Function logging_set_file_descriptors
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
test_file:
```
```bash
>>> local test_file="$(mktemp)"
>>> logging_set_file_descriptors "$test_file"
>>> logging_set_file_descriptors ""
>>> echo "test_file:" >"$test_file"
>>> logging.cat "$test_file"
>>> rm "$test_file"
test_file:
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=tee
>>> logging.plain foo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
foo
test_file:
foo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=off --commands=file
>>> logging.plain not shown
>>> echo foo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
test_file:
foo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=off
>>> logging.plain not shown
>>> echo foo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
foo
test_file:
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --commands=tee
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
logging
echo
test_file:
echo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --commands=file
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
logging
test_file:
echo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=file --commands=file
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
test_file:
logging
echo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=file --commands=file
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
test_file:
logging
echo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=file --commands=tee
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
echo
test_file:
logging
echo
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=file --commands=off
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
test_file:
logging
```
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging_set_file_descriptors "$test_file" --logging=tee --commands=tee
>>> logging.plain logging
>>> echo echo
>>> logging_set_file_descriptors ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
logging
echo
test_file:
logging
echo
```
Test exit handler
```bash
>>> local test_file fifo
>>> test_file="$(mktemp)"
>>> fifo=$(logging_set_file_descriptors "$test_file" --commands=tee; \
>>>    echo $logging_tee_fifo)
>>> [ -p "$fifo" ] || echo fifo deleted
>>> rm "$test_file"
fifo deleted
```
### Function logging_set_level
```bash
>>> logging.set_commands_level info
>>> logging.set_level info
>>> echo $logging_level
>>> echo $logging_commands_level
3
3
```
### Function logging_set_log_file
```bash
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging.set_log_file "$test_file"
>>> logging.plain logging
>>> logging.set_log_file "$test_file"
>>> echo echo
>>> logging.set_log_file ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
logging
echo
test_file:
logging
echo
```
```bash
>>> logging.set_commands_level debug
>>> logging.set_level debug
>>> local test_file="$(mktemp)"
>>> logging.plain "test_file:" >"$test_file"
>>> logging.set_log_file "$test_file"
>>> logging.plain 1
>>> logging.set_log_file ""
>>> logging.set_log_file "$test_file"
>>> logging.plain 2
>>> logging.set_log_file ""
>>> logging.cat "$test_file"
>>> rm "$test_file"
1
2
test_file:
1
2
```
## Module time
## Module ui
This module provides variables for printing colorful and unicode glyphs.
The Terminal features are detected automatically but can also be
enabled/disabled manually (see
[ui.enable_color](#function-ui_enable_color) and
[ui.enable_unicode_glyphs](#function-ui_enable_unicode_glyphs)).
### Function ui_disable_color
Disables color output explicitly.

```bash
>>> ui.enable_color
>>> ui.disable_color
>>> echo -E "$ui_color_red" red "$ui_color_default"
red
```
### Function ui_disable_unicode_glyphs
Disables unicode glyphs explicitly.

```bash
>>> ui.enable_unicode_glyphs
>>> ui.disable_unicode_glyphs
>>> echo -E "$ui_powerline_ok"
+
```
### Function ui_enable_color
Enables color output explicitly.

```bash
>>> ui.disable_color
>>> ui.enable_color
>>> echo -E $ui_color_red red $ui_color_default
[0;31m red [0m
```
### Function ui_enable_unicode_glyphs
Enables unicode glyphs explicitly.

```bash
>>> ui.disable_unicode_glyphs
>>> ui.enable_unicode_glyphs
>>> echo -E "$ui_powerline_ok"
✔
```
## Module utils
### Function utils_dependency_check
This function check if all given dependencies are present.

#### Example:

```bash
>>> utils_dependency_check mkdir ls; echo $?
0
```
```bash
>>> utils_dependency_check mkdir __not_existing__ 1>/dev/null; echo $?
2
```
```bash
>>> utils_dependency_check __not_existing__ 1>/dev/null; echo $?
2
```
```bash
>>> utils_dependency_check "ls __not_existing__"; echo $?
__not_existing__
2
```
### Function utils_dependency_check_pkgconfig
This function check if all given libraries can be found.

#### Example:

```bash
>>> utils_dependency_check_shared_library libc.so; echo $?
0
```
```bash
>>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
2
```
```bash
>>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?
2
```
### Function utils_dependency_check_shared_library
This function check if all given shared libraries can be found.

#### Example:

```bash
>>> utils_dependency_check_shared_library libc.so; echo $?
0
```
```bash
>>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
2
```
```bash
>>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?
2
```
### Function utils_find_block_device
```bash
>>> utils_find_block_device "boot_partition"
/dev/sdb1
```
```bash
>>> utils_find_block_device "boot_partition" /dev/sda
/dev/sda2
```
```bash
>>> utils_find_block_device "discoverable by blkid"
/dev/sda2
```
```bash
>>> utils_find_block_device "_partition"
/dev/sdb1 /dev/sdb2
```
```bash
>>> utils_find_block_device "not matching anything" || echo not found
not found
```
```bash
>>> utils_find_block_device "" || echo not found
not found
```
