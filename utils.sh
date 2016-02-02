#!/bin/env bash
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.import logging

utils_dependency_check_pkgconfig() {
    local __doc__='
    This function check if all given libraries can be found.

    Examples:

    >>> utils_dependency_check_shared_library "libc.so" && echo $?
    0
    >>> utils_dependency_check_shared_library "6GepJq295L" 1>/dev/null || echo $?
    1
    '
    utils_dependency_check 'pkg-config'
    local librariesToCheck="$1"
    local result=0
    local library
    for library in ${librariesToCheck[*]}; do
        if ! pkg-config "$library"; then
            logging.critical "Could not find library via pkg-config: '$library'"
            result=1
        fi
    done
    return $result
}
utils_dependency_check_shared_library() {
    local __doc__='
    This function check if all given shared libraries can be found.

    Examples:

    >>> utils_dependency_check_shared_library "libc.so" && echo $?
    0
    >>> utils_dependency_check_shared_library "6GepJq295L" 1>/dev/null || echo $?
    1
    '
    utils_dependency_check 'ldconfig'
    local librariesToCheck="$1"
    local result=0
    local pattern
    for pattern in ${librariesToCheck[*]}; do
        if ! ldconfig --print-cache | cut -f1 -d' ' | grep "$pattern" \
                >/dev/null; then
            logging.critical "Could not find shared library '$pattern'."
            result=1
        fi
    done
    return $result
}
utils_dependency_check() {
    local __doc__='
    This function check if all given dependencies are present.

    Examples:

    >>> utils_dependency_check "mkdir ls" && echo $?
    0
    >>> utils_dependency_check "mkdir 6GepJq295L" 1>/dev/null || echo $?
    1
    >>> utils_dependency_check "6GepJq295L" 1>/dev/null || echo $?
    1
    '
    local dependenciesToCheck="$1"
    local result=0
    local dependency
    for dependency in ${dependenciesToCheck[*]}; do
        if ! hash "$dependency" 2>/dev/null; then
            logging.error "Needed dependency \"$dependency\" isn't available."
            result=1
        fi
    done
    return $result
}
utils_find_block_device() {
    local partition_pattern="$1"
    local device="$2" # optional
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
        lsblk --noheadings --list --paths --output NAME $device \
        | sort -u | while read current_device; do
            device_info=$(blkid -p -o value "$current_device" | grep "$partition_pattern")
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
    local loopDevice=$(losetup -f)

    local sectorSize=$(blockdev --getbsz $device)
    # NOTE partx's NAME field corresponds to partition labels
    local partitionInfo=$(partx --raw --noheadings --output START,NAME,UUID,TYPE \
        $device 2>/dev/null| grep $nameOrUUID)
    local offsetSectors=$(echo $partitionInfo | cut -d' ' -f1)
    if [ -z "$offsetSectors" ]; then
        logging.warn "could not find partition with label/uuid '$nameOrUUID' on device $device"
        return 1
    fi
    #warn $(($offsetSectors*512)) # could overflow on 32bit systems
    local offsetBytes=$(echo | awk -v x=$offsetSectors -v y=$sectorSize '{print x * y}')

    # test if mount works directly (problem with btrfs device id)
    #mount -v -o loop,offset=$offsetBytes $device $mountPoint
    losetup -v -o $offsetBytes $loopDevice $device
    echo $loopDevice
}
alias utils.dependency_check="utils_dependency_check"
alias utils.find_block_device="utils_find_block_device"
alias utils.create_partition_via_offset="utils_create_partition_via_offset"
