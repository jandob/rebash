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
