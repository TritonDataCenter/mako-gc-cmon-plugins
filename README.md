# mako-gc-cmon-plugins

## Overview

This repo contains the code for cmon-agent plugins used for development and
debugging the work on mako-gc. Each plugin lives in a subdirectory and is used
to report some set of statistics that might be useful.

## Plugins

| Name | Description |
| ---- | ----------- |
| [mako_gc_files](./mako_gc_files) | Tracks the number of /var/tmp/INPUTS files and the number of lines they contain |
| [manta_gw_ping](./manta_gw_ping) | Tracks whether a zone can ping its gateway (if it has one) |
| [zpool_creation](./zpool_creation) | Indicates the creation time of the system's zpool (as a proxy for system age) |
