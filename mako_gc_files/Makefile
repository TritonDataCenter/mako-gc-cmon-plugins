#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2019 Joyent, Inc.
#

mako_gc_files: mako_gc_files.c
	$(CC) -Wall -o $@ $<

.PHONY: clean
clean:
	rm -f mako_gc_files
