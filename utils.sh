#!/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
core.import logging

utils_dependency_check_pkgconfig() {
    local __doc__='
    This function check if all given libraries can be found.

    Examples:

    >>> utils_dependency_check_shared_library libc.so; echo $?
    0
    >>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
    1
    >>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?
    1
    '
    local result=0
    local library

    utils_dependency_check pkg-config || \
        logging.critical 'Missing dependency "ldconfig" to check for packages.' && \
        return 1
    for library in $@; do
        if ! pkg-config "$library"; then
            result=2
            echo "$library"
        fi
    done
    return $result
}
utils_dependency_check_shared_library() {
    local __doc__='
    This function check if all given shared libraries can be found.

    Examples:

    >>> utils_dependency_check_shared_library libc.so; echo $?
    0
    >>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
    1
    >>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?
    1
    '
    local result=0
    local pattern

    utils_dependency_check ldconfig || \
        logging.critical 'Missing dependency "ldconfig".' && \
        echo logging.get_level && \
        return 1
    for pattern in $@; do
        if ! ldconfig --print-cache | cut --fields 1 --delimiter ' ' | \
            grep "$pattern" >/dev/null
        then
            result=2
            echo "$pattern"
        fi
    done
    return $result
}
utils_dependency_check() {
    local __doc__='
    This function check if all given dependencies are present.

    Examples:

    >>> utils_dependency_check mkdir ls; echo $?
    0
    >>> utils_dependency_check mkdir __not_existing__ 1>/dev/null; echo $?
    1
    >>> utils_dependency_check __not_existing__ 1>/dev/null; echo $?
    1
    >>> utils_dependency_check "ls __not_existing__"; echo $?
    __not_existing__
    1
    '
    local result=0
    local dependency

    for dependency in $@; do
        if ! hash "$dependency" 2>/dev/null; then
            result=2
            echo "$dependency"
        fi
    done
    return $result
}
utils_find_block_device() {
    local partition_pattern="$1"
    local device="$2"

    [ "$partition_pattern" = "" ] && return 0
    shopt -s lastpipe
    utils_find_block_device_simple() {
        local device_info
        lsblk --noheadings --list --paths --output \
        NAME,TYPE,LABEL,PARTLABEL,UUID,PARTUUID,PARTTYPE $device \
        | sort -u | while read device_info; do
            local current_device=$(echo $device_info | cut -d' ' -f1)
            if [[ "$device_info" = *"${partition_pattern}"* ]]; then
                candidates+=("$current_device")
            fi
        done
    }
    utils_find_block_device_deep() {
        local device_info

        lsblk --noheadings --list --paths --output NAME "$device" | \
        sort --unique | \
        while read current_device; do
            device_info=$(blkid -p -o value "$current_device" | grep \
                "$partition_pattern")
            if [ $? -eq 0 ]; then
                candidates+=("$current_device")
            fi
        done
    }
    utils_find_block_device_simple
    [ ${#candidates[@]} -eq 0 ] && utils_find_block_device_deep
    [ ${#candidates[@]} -ne 1 ] && echo ${candidates[@]} && return 1
    logging.plain "$candidates"
    shopt -u lastpipe
    unset -f utils_find_block_device_simple
    unset -f utils_find_block_device_deep
}
utils_create_partition_via_offset() {
    local device="$1"
    local nameOrUUID="$2"
    local loopDevice="$(losetup --find)"
    local sectorSize="$(blockdev --getbsz "$device")"

    # NOTE: partx's NAME field corresponds to partition labels
    local partitionInfo=$(partx --raw --noheadings --output \
        START,NAME,UUID,TYPE "$device" 2>/dev/null| grep "$nameOrUUID")
    local offsetSectors="$(echo "$partitionInfo"| cut --delimiter ' ' \
        --fields 1)"
    if [ -z "$offsetSectors" ]; then
        logging.warn "Could not find partition with label/uuid \"$nameOrUUID\" on device \"$device\""
        return 1
    fi
    local offsetBytes="$(echo | awk -v x="$offsetSectors" -v y="$sectorSize" '{print x * y}')"
    losetup --offset "$offsetBytes" "$loopDevice" "$device"
    logging.plain "$loopDevice"
}
alias utils.dependency_check_pkgconfig="utils_dependency_check_pkgconfig"
alias utils.dependency_check_shared_library="utils_dependency_check_shared_library"
alias utils.dependency_check="utils_dependency_check"
alias utils.find_block_device="utils_find_block_device"
alias utils.create_partition_via_offset="utils_create_partition_via_offset"
