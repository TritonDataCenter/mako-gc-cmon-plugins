#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2019 Joyent, Inc.
#
#
# Usage: feeder_gc_queued.sh <zonename>
#
# This is intended to run as a cmon-agent VM plugin in order to get information
# about the processing of GC instructions files in a Manta feeder zone.
#

TARGET_ZONE="{{UUID}}"
TARGET_DIR="/zones/$TARGET_ZONE/root/var/spool/manta_gc/mako"

set -o errexit

zonename=$1
[[ $zonename != $TARGET_ZONE ]] && exit 0

if [[ ! -x /opt/custom/bin/instruction_counter ]]; then
    echo "WARN: Missing instruction_counter, cannot continue." >&2
    exit 0
fi

printf "ttl\toption\t15\n"

for dir in $(find $TARGET_DIR/[0-9]* -maxdepth 1 -type d); do
    storId=$(basename $dir)
    values=$(/opt/custom/bin/instruction_counter $dir)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo "Failed to count instructions: code $result" >&2
        exit 1
    fi

    files="${values% *}"
    lines="${values#* }"

    printf "instructions{storageId=\"$storId\"}\tgauge\t$lines\tNumber of instruction lines in feeder GC queue to be sent to mako.\n"
    printf "instruction_files{storageId=\"$storId\"}\tgauge\t$files\tNumber of instruction files in feeder GC queue to be sent to mako.\n"
done

feeder_read_count=$(cat /zones/$TARGET_ZONE/root/var/spool/manta_gc/metrics/feeder_read_count)
[[ -z $feeder_read_count ]] && feeder_read_count=0
printf "instruction_files_read\tcounter\t$feeder_read_count\tNumber of instruction files rsync'd to feeder from garbage-collector.\n"

exit 0
