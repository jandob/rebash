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
