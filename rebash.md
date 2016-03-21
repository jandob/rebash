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
