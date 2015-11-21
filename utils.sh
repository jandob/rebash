#!/usr/bin/sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.check_namespace 'utils'
core.import logging

utils_dependency_check() {
    # This function check if all given dependencies are present.
    #
    # Examples:
    #
    # >>> utils_dependency_check "mkdir pacstrap mktemp"
    # ...
    local dependenciesToCheck="$1"
    local result=0
    local dependency
    for dependency in ${dependenciesToCheck[*]}; do
        if ! hash "$dependency"; then
            logging.error "Needed dependency \"$dependency\" isn't available."
            result=1
        fi
    done
    return $result
}
alias utils.dependency_check="utils_dependency_check"
