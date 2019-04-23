#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2019 Joyent, Inc.
#
#
# Usage: mako_bytes.sh <zonename>
#
# This is intended to run as a cmon-agent VM plugin in order to get information
# about the number of physical/logical bytes deleted for a Mako zone.
#

# Check that we're dealing with a mako
IS_MAKO=$(vmadm lookup uuid=$1 tags.manta_role=storage)
if [[ -z "$IS_MAKO" ]]; then
    exit 0
fi

BP_FILE="/zones/$1/root/var/tmp/bytes_processed"
TOTAL_LOGICAL_BYTES="0"
TOTAL_PHYSICAL_BYTES="0"
LBYTES_LINE="0"
LBYTES="0"
PBYTES_LINE="0"
PBYTES="0"

if [[ -f $BP_FILE ]]; then
    mapfile -t LAST_FOUR_LINES  < <(tail -n 4 $BP_FILE)
fi

if [[ ${#LAST_FOUR_LINES[@]} -eq 4 ]]; then
    LBYTES_LINE=${LAST_FOUR_LINES[1]}
    PBYTES_LINE=${LAST_FOUR_LINES[3]}
    TOTAL_LOGICAL_BYTES=$(echo "$LBYTES_LINE" | awk '{ print $8 }')
    TOTAL_PHYSICAL_BYTES=$(echo "$PBYTES_LINE"| awk '{ print $8 }')
fi


echo -e "mako_logical_bytes_deleted_total\tgauge\t$TOTAL_LOGICAL_BYTES"
echo -e "mako_physical_bytes_deleted_total\tgauge\t$TOTAL_PHYSICAL_BYTES"
