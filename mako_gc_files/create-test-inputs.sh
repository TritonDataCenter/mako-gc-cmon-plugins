#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2022 Joyent, Inc.
#
#
# Usage: create-test-inputs.sh <numInputs>
#
# This script is intended to be used to create test data with which to test
# the mako_gc_files plugin. It will create an INPUTS directory which will
# contain files with up to 100 paths each.
#
# E.g. If you specify:
#
#  create-test-inputs.sh 999
#
# You should end up with 10 INPUTS/* files. 9 of these files will have 100
# paths, the last will have 99 paths.
#
# IMPORTANT: this must be run in a zone with split from pkgsrc in the path. If
# using /usr/bin/split on SmartOS you'll be limited to 676 output files and if
# you pass that you'll get an error:
#
#   split: Exhausted output file names, aborting split
#   xargs: Child killed with signal 13
#
#

set -o errexit

numInputs=$1
system=$(uname -s)

if [[ -z $numInputs || -n $2 ]]; then
    echo "Usage: $0 <numInputs>" >&2
    exit 2
fi

rm -rf INPUTS
mkdir INPUTS

function newUuid() {
    if [[ ${system} == "Darwin" ]]; then
        uuidgen | tr "[:upper:]" "[:lower:]"
    else
        uuid -v 4
    fi
}

storShard="430.stor.us-east.joyent.us"
morayShard="23.moray.us-east.joyent.us"
makoUuid=$(newUuid);

inputBase=$(pwd)/INPUTS
instructionsBase=$(pwd)/manta_gc/mako/${storShard}

seq 0 $((numInputs - 1)) \
    | xargs -L 1 -I '{}' echo "${instructionsBase}/$(date -u +%Y-%m-%d-%H:%M:%S)-${makoUuid}-X-$(newUuid)-mako-${storShard}" \
    | split -l 100 - "${inputBase}/${storShard}-${morayShard}"
