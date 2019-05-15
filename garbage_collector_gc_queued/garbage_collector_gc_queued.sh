#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2019 Joyent, Inc.
#
#
# Usage: garbage_collector_gc_queued.sh <zonename>
#
# This is intended to run as a cmon-agent VM plugin in order to get information
# about the processing of GC instructions files in a Manta garbage-collector
# zone.
#

if [[ -n $TRACE ]]; then
    set -o xtrace
fi

if [[ -z $1 ]]; then
    exit 0;
fi

ZONE="$1"
ZONEROOT="/zones/$ZONE"

INSTRUCTION_SPOOL="$ZONEROOT/root/var/spool/manta_gc/mako"

if [[ ! -d $INSTRUCTION_SPOOL ]]; then
    # Doesn't have instructions, so we don't care to ensure it's a
    # garbage-collector zone.
    exit 0
fi

# Check that we're dealing with a garbage-collector, we take a shortcut here to
# cut down on processing.
read MANTA_ROLE <<<$(json manta_role <$ZONEROOT/config/tags.json)

if [[ "$MANTA_ROLE" != "garbage-collector" ]]; then
    # Not a garbage-collector.
    exit 0
fi

if [[ ! -x /opt/custom/bin/instruction_counter ]]; then
    echo "WARN: Missing instruction_counter, cannot continue." >&2
    exit 0
fi

printf "ttl\toption\t15\n"

values=$(/opt/custom/bin/instruction_counter $INSTRUCTION_SPOOL)
result=$?
if [[ $result -ne 0 ]]; then
    echo "Failed to count instructions: code $result" >&2
    exit 1
fi

files="${values% *}"
lines="${values#* }"

printf "instructions\tgauge\t$lines\tNumber of instruction lines in garbage-collector zone GC queue to be sent to feeders.\n"
printf "instruction_files\tgauge\t$files\tNumber of instruction files in garbage-collector zone GC queue to be sent to feeders.\n"

exit 0
