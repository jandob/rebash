# ReBash - bash/shell library/framework
## Features
- modular import system
- advanced logging (colors, control stdout/stderr, log levels, ...)
- error handling (exceptions, try-catch)
- doc testing inspired by python
- documentation generation
- argument parser

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
## Module array
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
## Module dictionary
### Function dictionary_get


Usage:
variable=$(dictionary.get dictionary_name key)

Examples:

```bash
>>> dictionary_get unset_map unset_value
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


Usage:
dictionary.set dictionary_name key value

Tests:

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
>>> [ -z "$testing" ] && echo empty
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
## Module documentation
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

Reraise exception
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
>>>     local path="${BASH_SOURCE[2]##./}"
>>>     path=$(basename "$path")
>>>     echo "[myprefix - ${level}:${path}]"
>>> }
>>> logging.critical foo
[myprefix - critical:doc_test.sh] foo
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
## Module ui


This module provides variables for printing colorful and unicode glyphs.
The Terminal features are detected automatically but can also be
enabled/disabled manually (see
[ui.enable_color](#function-ui_enable_color) and
[ui.enable_unicode_glyphs](#function-ui_enable_unicode_glyphs)).
## Module utils
