# mako_bytes.sh

## Overview

This is a cmon-agent VM plugin to provide insight into how much physical/logical
data has been deleted by a Mako.

If the zone does not look like a Mako zone, it exits.

It then looks at the last 4 lines of the `/var/tmp/bytes_processed` file to
determine the number of physical and logical bytes that have been deleted and
exposes those as metrics.

When the plugin runs successfully, it will provide the metrics that look like:

```
$ p /opt/custom/cmon/vm-plugins/mako_bytes.sh 97d0868e-3a6d-436c-8d02-0ee988b8fc5f
mako_logical_bytes_deleted_total        gauge   394907670057
mako_physical_bytes_deleted_total       gauge   0
$
```


## Installation

See ["Plugins" section in cmon-agent's README.md](https://github.com/joyent/triton-cmon-agent/blob/master/docs/README.md#plugins).
But basically you want to create a /opt/custom/cmon/vm-plugins/ directory and
install the `mako_bytes.sh` script to it making sure to set it executable. Once
the script is in place and the permissions are set correctly, it should be used
immediately when CMON is next queried for any zone on the system.

To test that you have installed correctly you can run (on the CN where this is
installed):

```
curl -sS http://<ADMIN_IP>:9163/v1/<VM_UUID>/metrics | grep mako_bytes
```

replacing `<ADMIN_IP>` with the admin IP of your CN and replacing `<VM_UUID>`
with the UUID of your Mako zone. If you do this you should see output that
looks something like:

```
# HELP plugin_mako_bytes_metrics_available_boolean Whether plugin_mako_bytes metrics were available, 0 = false, 1 = true
# TYPE plugin_mako_bytes_metrics_available_boolean gauge
plugin_mako_bytes_metrics_available_boolean 1
# HELP plugin_mako_bytes_metrics_cached_boolean Whether plugin_mako_bytes metrics came from cache, 0 = false, 1 = true
# TYPE plugin_mako_bytes_metrics_cached_boolean gauge
plugin_mako_bytes_metrics_cached_boolean 1
# HELP plugin_mako_bytes_metrics_timer_seconds How long it took to gather the plugin_mako_bytes metrics
# TYPE plugin_mako_bytes_metrics_timer_seconds gauge
plugin_mako_bytes_metrics_timer_seconds 0.000067992
# HELP plugin_mako_bytes_mako_logical_bytes_deleted_total mako_logical_bytes_deleted_total
# TYPE plugin_mako_bytes_mako_logical_bytes_deleted_total gauge
plugin_mako_bytes_mako_logical_bytes_deleted_total 395558711339
# HELP plugin_mako_bytes_mako_physical_bytes_deleted_total mako_physical_bytes_deleted_total
# TYPE plugin_mako_bytes_mako_physical_bytes_deleted_total gauge
plugin_mako_bytes_mako_physical_bytes_deleted_total 0
```

in which case the plugin is working.

If you do not see this, there should be something in the log at:

```
/var/svc/log/smartdc-agent-cmon-agent\:default.log
```
```

to help you figure out what's wrong.
