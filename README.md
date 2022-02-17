# mako-gc-cmon-plugins

## Overview

This repo contains the code for cmon-agent plugins used for development and
debugging the work on mako-gc. Each plugin lives in a subdirectory and is used
to report some set of statistics that might be useful.

These plugins aren't generally useful to Triton users without MantaV2, and
mostly only useful to MantaV2 users needing to diagnose GC issues.

Some of the plugins are under-documented.

## Plugins

| Name | Description |
| ---- | ----------- |
| [mako_bytes](./mako_bytes) | Provides information about the number of physical/logcal bytes deleted for a Mako zone |
| [mako_gc_files](./mako_gc_files) | Tracks the number of /var/tmp/INPUTS files and the number of lines they contain |
| [manta_gw_ping](./manta_gw_ping) | Tracks whether a zone can ping its gateway (if it has one) |
| [zpool_creation](./zpool_creation) | Indicates the creation time of the system's zpool (as a proxy for system age) |
