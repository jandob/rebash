# ReBash - bash/shell library/framework
## Features
- modular import system
- advanced logging (colors, control stdout/stderr, log levels, ...)
- error handling (exceptions, try-catch)
- doc testing inspired by python
- documentation generation
- argument parser

## Usage
Source the [core](#module-core) module and use `core.import` to import
other modules.
```
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
module name. E.g. `core_import`. Aliases inside the module are used to define
public functions and to have a convinient way to distinguish the module
namespace from the function (`alias core.import="core_import"`).

A typical minimal module looks like this (with filename `mockup.sh`):
```
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
core.import logging
mockup_foo() {
    echo foo
}
alias mockup.foo="mockup_foo"
```
