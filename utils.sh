#!/usr/bin/sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
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
utils_find_block_device() {
    local partition_pattern="$1"
    local device="$2" # optional
    [ "$partition_pattern" = "" ] && return 0
    local device_info
    lsblk --noheadings --list --paths --output \
    NAME,TYPE,LABEL,PARTLABEL,UUID,PARTUUID,PARTTYPE "$device" \
    | while read device_info; do
        local current_device=$(echo $device_info | cut -d' ' -f1)
        if [[ "$device_info" = *"${partition_pattern}"* ]]; then
            logging.plain $current_device
            return
        fi
        if [ "$(blkid -p -o export "$current_device" \
                | grep $partition_pattern)" != "" ]; then
            logging.plain $current_device
            return
        fi
    done
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
