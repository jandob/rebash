#!/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
core.import logging

utils_dependency_check_pkgconfig() {
    local __doc__='
    This function check if all given libraries can be found.

    Examples:

    >>> utils_dependency_check_shared_library libc.so; echo $?
    0
    >>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
    2
    >>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?
    2
    '
    local return_code=0
    local library

    if ! utils_dependency_check pkg-config &>/dev/null; then
        logging.critical 'Missing dependency "pkg-config" to check for packages.'
        return 1
    fi
    for library in $@; do
        if ! pkg-config "$library" &>/dev/null; then
            return_code=2
            echo "$library"
        fi
    done
    return $return_code
}
utils_dependency_check_shared_library() {
    local __doc__='
    This function check if all given shared libraries can be found.

    Examples:

    >>> utils_dependency_check_shared_library libc.so; echo $?
    0
    >>> utils_dependency_check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
    2
    >>> utils_dependency_check_shared_library __not_existing__ 1>/dev/null; echo $?
    2
    '
    local return_code=0
    local pattern

    if ! utils_dependency_check ldconfig &>/dev/null; then
        logging.critical 'Missing dependency "ldconfig" to check for shared libraries.'
        return 1
    fi
    for pattern in $@; do
        if ! ldconfig --print-cache | cut --fields 1 --delimiter ' ' | \
            grep "$pattern" &>/dev/null
        then
            return_code=2
            echo "$pattern"
        fi
    done
    return $return_code
}
utils_dependency_check() {
    # shellcheck disable=SC2034
    local __doc__='
    This function check if all given dependencies are present.

    Examples:

    >>> utils_dependency_check mkdir ls; echo $?
    0
    >>> utils_dependency_check mkdir __not_existing__ 1>/dev/null; echo $?
    2
    >>> utils_dependency_check __not_existing__ 1>/dev/null; echo $?
    2
    >>> utils_dependency_check "ls __not_existing__"; echo $?
    __not_existing__
    2
    '
    local return_code=0
    local dependency

    if ! hash &>/dev/null; then
        logging.critical 'Missing dependency "hash" to check for available executables.'
        return 1
    fi
    for dependency in $@; do
        if ! hash "$dependency" &>/dev/null; then
            return_code=2
            echo "$dependency"
        fi
    done
    return $return_code
}
utils_find_block_device() {
    local partition_pattern="$1"
    local device="$2"

    [ "$partition_pattern" = "" ] && return 0
    shopt -s lastpipe
    utils_find_block_device_simple() {
        local device_info
        lsblk --noheadings --list --paths --output \
        NAME,TYPE,LABEL,PARTLABEL,UUID,PARTUUID,PARTTYPE "$device" \
        | sort -u | while read -r device_info; do
            local current_device
            current_device=$(echo "$device_info" | cut -d' ' -f1)
            if [[ "$device_info" = *"${partition_pattern}"* ]]; then
                echo "$current_device"
            fi
        done
    }
    utils_find_block_device_deep() {
        local device_info

        lsblk --noheadings --list --paths --output NAME "$device" | \
        sort --unique | \
        while read -r current_device; do
            device_info=$(blkid -p -o value "$current_device" | grep \
                "$partition_pattern")
            if [ $? -eq 0 ]; then
                echo "$current_device"
            fi
        done
    }
    local candidates
    candidates=($(utils_find_block_device_simple))
    [ ${#candidates[@]} -eq 0 ] && candidates=($(utils_find_block_device_deep))
    shopt -u lastpipe
    unset -f utils_find_block_device_simple
    unset -f utils_find_block_device_deep
    [ ${#candidates[@]} -ne 1 ] && echo "${candidates[@]}" && return 1
    logging.plain "${candidates[0]}"
}
utils_create_partition_via_offset() {
    local device="$1"
    local nameOrUUID="$2"
    local loop_device
    loop_device="$(losetup --find)"
    local sector_size
    sector_size="$(blockdev --getbsz "$device")"

    # NOTE: partx's NAME field corresponds to partition labels
    local partitionInfo
    partitionInfo=$(partx --raw --noheadings --output \
        START,NAME,UUID,TYPE "$device" 2>/dev/null| grep "$nameOrUUID")
    local offsetSectors
    offsetSectors="$(echo "$partitionInfo"| cut --delimiter ' ' \
        --fields 1)"
    if [ -z "$offsetSectors" ]; then
        logging.warn "Could not find partition with label/uuid \"$nameOrUUID\" on device \"$device\""
        return 1
    fi
    local offsetBytes
    offsetBytes="$(echo | awk -v x="$offsetSectors" -v y="$sector_size" '{print x * y}')"
    losetup --offset "$offsetBytes" "$loop_device" "$device"
    logging.plain "$loop_device"
}
alias utils.dependency_check_pkgconfig="utils_dependency_check_pkgconfig"
alias utils.dependency_check_shared_library="utils_dependency_check_shared_library"
alias utils.dependency_check="utils_dependency_check"
alias utils.find_block_device="utils_find_block_device"
alias utils.create_partition_via_offset="utils_create_partition_via_offset"
