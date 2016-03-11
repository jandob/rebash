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
- [core](#Module-core)
- [logging](#Module-logging)
- [ui](#Module-ui)
- [exceptions](#Module-exceptions)
- [doc_test](#Module-doc_test)
- [documentation](#Module-documentation)
