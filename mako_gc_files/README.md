# mako_gc_files

## Overview

This is a plugin to provide insight into the number of `/var/tmp/INPUT/*` files
on each Mako zone and the total number of lines among these files.

It loads the INPUTS directory list and then reads the first `PATH_MAX` bytes of
the first file and determines the line length based on the position of the first
`\n` character. It has been stated that these paths will always be of constant
length across all files on a given Mako, so once we know how long each line is
we can from that point `stat()` all the files and divide the file size by the
number of bytes per line in order to calculate the number of lines.

It has been tested with over 66K "INPUTS" files (>6.6M "instructions" files) and
still returns in < 0.33 seconds even in a zone on a fairly busy test system.


## Testing Quickstart

```
$ make
cc -Wall -o mako_gc_files mako_gc_files.c
$ ./create-test-inputs.sh 999
$ INPUT_DIR=$(pwd)/INPUTS ./mako_gc_files $(uuidgen)
input_file_count	gauge	10	Number of files in /var/tmp/INPUT for a Mako.
instruction_file_count	gauge	999	Number of instruction files listed in /var/tmp/INPUT files for a Mako.
$
```


## Installation

See ["Plugins" section in cmon-agent's README.md](https://github.com/joyent/triton-cmon-agent/blob/master/docs/README.md#plugins).
But basically you want to create a /opt/custom/cmon/vm-plugins/ directory and
install the `mako_gc_files` binary to it making sure to set it executable. Once
the binary is in place and the permissions are set correctly, it should be used
immediately when CMON is next queried for the Mako zone.

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

To test that you have installed correctly you can run (on the CN where this is
installed):

```
curl -sS http://<ADMIN_IP>:9163/v1/c4408df1-5dbc-4a46-96d0-0a2173458a38/metrics | grep mako_gc_files
```

replacing `<ADMIN_IP>` with the admin IP of your CN and replacing
`c4408df1-5dbc-4a46-96d0-0a2173458a38` with the UUID of your Mako zone. If you
do this you should see output that looks something like:

```
# HELP plugin_mako_gc_files_metrics_available_boolean Whether plugin_mako_gc_files metrics were available, 0 = false, 1 = true
# TYPE plugin_mako_gc_files_metrics_available_boolean gauge
plugin_mako_gc_files_metrics_available_boolean 1
# HELP plugin_mako_gc_files_metrics_cached_boolean Whether plugin_mako_gc_files metrics came from cache, 0 = false, 1 = true
# TYPE plugin_mako_gc_files_metrics_cached_boolean gauge
plugin_mako_gc_files_metrics_cached_boolean 1
# HELP plugin_mako_gc_files_metrics_timer_seconds How long it took to gather the plugin_mako_gc_files metrics
# TYPE plugin_mako_gc_files_metrics_timer_seconds gauge
plugin_mako_gc_files_metrics_timer_seconds 0.000024484
# HELP plugin_mako_gc_files_input_file_count Number of files in /var/tmp/INPUT for a Mako.
# TYPE plugin_mako_gc_files_input_file_count gauge
plugin_mako_gc_files_input_file_count 0
# HELP plugin_mako_gc_files_instruction_file_count Number of instruction files listed in /var/tmp/INPUT files for a Mako.
# TYPE plugin_mako_gc_files_instruction_file_count gauge
plugin_mako_gc_files_instruction_file_count 0
```

in which case the plugin is working.
