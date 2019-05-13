#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2019 Joyent, Inc.
#
#
# Usage: mako_gc.sh <zonename>
#
# This is intended to run as a cmon-agent VM plugin in order to get information
# about the processing of GC instructions files in a Manta Mako zone.
#

if [[ -n $TRACE ]]; then
    set -o xtrace
fi

if [[ -z $1 ]]; then
    exit 0;
fi

LABELS=""
ZONE="$1"
ZONEROOT="/zones/$ZONE"

INSTRUCTION_SPOOL="$ZONEROOT/root/var/spool/manta_gc/instructions"
METRICS_FILE="$ZONEROOT/root/var/spool/manta_gc/metrics/mako_gc"

if [[ ! -f $METRICS_FILE ]]; then
    # Doesn't have a metrics file, so we don't care to ensure it's a mako zone.
    exit 0
fi

# Check that we're dealing with a mako, we take a shortcut here to cut
# down on processing.
read MANTA_ROLE MANTA_STORAGE_ID <<<$(json manta_role manta_storage_id <$ZONEROOT/config/tags.json)

if [[ "$MANTA_ROLE" != "storage" ]]; then
    # Not a mako.
    exit 0
fi

if [[ -n "$MANTA_STORAGE_ID" ]]; then
    LABELS="{storageId=\"$MANTA_STORAGE_ID\"}"
fi


METRIC_RSYNC_FILES=0
METRIC_PROCESSED_FILES=0
METRIC_INSTRUCTIONS_INVALID=0
METRIC_INSTRUCTIONS_MISDIRECTED=0
METRIC_INSTRUCTIONS_TOTAL=0
METRIC_LOGICAL_BYTES=0
METRIC_MISSING_FILES=0
METRIC_PHYSICAL_BYTES=0

# This function is taken directly from the mako_mantaless_gc.sh script

function load_metrics {
    local rsync_files
    local processed_files
    local missing_files
    local instructions_total
    local instructions_invalid
    local instructions_misdirected
    local logical_bytes
    local physical_bytes

    #
    # It's important that the order here match that in write_metrics.
    #
    read \
        rsync_files \
        processed_files \
        missing_files \
        instructions_total \
        instructions_invalid \
        instructions_misdirected \
        logical_bytes \
        physical_bytes \
        <<<$(head -1 $METRICS_FILE || true)

    #
    # We ensure all the values are set and numbers. If they're negative
    # (because of a bug/rollover) they'll not match our regex here and we will
    # leave them set to 0 (initialized above) which works just fine for
    # Prometheus counters. Fwiw on the bash we'll be using the max value is
    # 9223372036854775807 before rollover.
    #
    [[ -n $rsync_files && "$rsync_files" =~ ^[0-9]+$ ]] \
        && METRIC_RSYNC_FILES=$rsync_files
    [[ -n $processed_files && "$processed_files" =~ ^[0-9]+$ ]] \
        && METRIC_PROCESSED_FILES=$processed_files
    [[ -n $missing_files && "$missing_files" =~ ^[0-9]+$ ]] \
        && METRIC_MISSING_FILES=$missing_files
    [[ -n $instructions_total && "$instructions_total" =~ ^[0-9]+$ ]] \
        && METRIC_INSTRUCTIONS_TOTAL=$instructions_total
    [[ -n $instructions_invalid && "$instructions_invalid" =~ ^[0-9]+$ ]] \
        && METRIC_INSTRUCTIONS_INVALID=$instructions_invalid
    [[ -n $instructions_misdirected && "$instructions_misdirected" =~ ^[0-9]+$ ]] \
        && METRIC_INSTRUCTIONS_MISDIRECTED=$instructions_misdirected
    [[ -n $logical_bytes && "$logical_bytes" =~ ^[0-9]+$ ]] \
        && METRIC_LOGICAL_BYTES=$logical_bytes
    [[ -n $physical_bytes && "$physical_bytes" =~ ^[0-9]+$ ]] \
        && METRIC_PHYSICAL_BYTES=$physical_bytes

    LOADED_METRICS=1
}


printf "ttl\toption\t15\n"

if [[ -x /opt/custom/bin/instruction_counter ]]; then
    values=$(/opt/custom/bin/instruction_counter $INSTRUCTION_SPOOL)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo "Failed to count instructions: code $result" >&2
        exit 1
    fi

    files="${values% *}"
    lines="${values#* }"

    printf "instructions_queued$LABELS\tgauge\t$lines\tNumber of instruction lines in mako queue to be processed.\n"
    printf "instruction_files_queued$LABELS\tgauge\t$files\tNumber of instruction files in mako queue to be processed.\n"
fi

load_metrics

printf "rsync_files_total$LABELS\tcounter\t$METRIC_RSYNC_FILES\tTotal number of files received via rsync\n"
printf "files_processed_total$LABELS\tcounter\t$METRIC_PROCESSED_FILES\tTotal number of files processd by mako gc script\n"
printf "missing_files_total$LABELS\tcounter\t$METRIC_MISSING_FILES\tTotal number of files that were missing on this mako when delete was attempted\n"
printf "instructions_total$LABELS\tcounter\t$METRIC_INSTRUCTIONS_TOTAL\tTotal number of instructions seen in the processed files\n"
printf "invalid_instructions_total$LABELS\tcounter\t$METRIC_INSTRUCTIONS_INVALID\tTotal number of instructions with the wrong number of fields\n"
printf "misdirected_instructions_total$LABELS\tcounter\t$METRIC_INSTRUCTIONS_MISDIRECTED\tTotal number of instructions received that were not for this mako\n"
printf "logical_bytes_deleted_total$LABELS\tcounter\t$METRIC_LOGICAL_BYTES\tTotal number of logical bytes among files deleted by GC on this mako\n"
printf "physical_bytes_deleted_total$LABELS\tcounter\t$METRIC_PHYSICAL_BYTES\tTotal number of physical bytes among files deleted by GC on this mako\n"

exit 0
