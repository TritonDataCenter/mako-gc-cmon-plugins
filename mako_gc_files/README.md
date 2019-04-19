# mako_gc_files

## Overview

TODO

## Quickstart Testing

```
failhammer:mako_gc_files joshw$ make
cc -Wall -o mako_gc_files mako_gc_files.c
failhammer:mako_gc_files joshw$ ./create-test-inputs.sh 999
failhammer:mako_gc_files joshw$ INPUT_DIR=$(pwd)/INPUTS ./mako_gc_files $(uuidgen)
input_file_count	gauge	10	Number of files in /var/tmp/INPUT for a Mako.
instruction_file_count	gauge	999	Number of instruction files listed in /var/tmp/INPUT files for a Mako.
failhammer:mako_gc_files joshw$
```

## Installation

See ["Plugins" section in cmon-agent's README.md](https://github.com/joyent/triton-cmon-agent/blob/master/docs/README.md#plugins).
But basically you want to create a /opt/custom/cmon/vm-plugins/ directory and
install the `mako_gc_files` binary to it making sure to set it executable.

Then you can also optionally create a /opt/custom/cmon/vm-plugins/plugin.json in
that includes something like:

```
{
    "mako_gc_files": {
        "timeout": 500,
        "ttl": 60
        "vms": [
            "6557450a-4bff-424e-83ca-da45535ae349"
        ]
    }
}
```

where `6557450a-4bff-424e-83ca-da45535ae349` is the zonename/uuid of your
storage zone. This is optional, since without this the plugin will just exit
immediately for any zone that doesn't have a /var/tmp/INPUTS, but it would save
having to exec the plugin each time to find that out.
