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

## Modules
### core
- import other modules

`core.import` <module>

### logging
- set global log level, one of (error critical warn info debug)

`logging.set_level='logging_set_level'`
- set log level for commands, one of (error critical warn info debug)

`logging.set_commands_level`
- log at the different levels, prints extra info (log-level, file and linenumber)

```
logging.log <level> "hello"
logging.error "hello"
logging.critical "hello"
logging.warn "hello"
logging.info "hello"
logging.debug "hello"
```
- log without printing extrainfo (respects 'commands_level')

`logging.plain`
- print files, heredocs etc, uses cat internally (respects 'commands_level')
`logging.cat < hello.txt`

### ui
variables for printing in color and unicode glyphs
- features are detected automatically, but can also be enabled/disabled manually
```
ui.enable_color
ui.disable_color
ui.enable_unicode_glyphs
ui.disable_unicode_glyphs
```

### doctest
TODO

### exceptions
TODO
