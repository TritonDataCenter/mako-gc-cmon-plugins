# zpool_creation

## Overview

This is a plugin to provide insight into the creation timestamp of the zpool.
This can be used as a proxy in order to get a sense for how old the system is.
It simply reads the 'Zpool Creation' field from sysinfo and exposes it with a
long TTL since this value should never change while the system is running.

When run manually you should see something like:

```
# /opt/custom/cmon/gz-plugins/zpool_creation global
ttl	option	86400
timestamp_seconds	gauge	1546505749	Number of seconds after UNIX epoch when the system's zpool was created.
#
```

if the plugin is working correctly.


## Installation

See ["Plugins" section in cmon-agent's README.md](https://github.com/joyent/triton-cmon-agent/blob/master/docs/README.md#plugins).
But basically you want to create a /opt/custom/cmon/gz-plugins/ directory and
install the `zpool_creation` script to it making sure to set it executable. Once
the script is in place and the permissions are set correctly, it should be used
immediately when CMON is next queried for the global zone.

To test that you have installed correctly you can run (on the CN where this is
installed):

```
curl -sS http://<ADMIN_IP>:9163/v1/gz/metrics | grep zpool_creation
```

replacing `<ADMIN_IP>` with the actual admin IP of your CN. And you should see
output that looks something like:

```
# HELP plugin_zpool_creation_metrics_available_boolean Whether plugin_zpool_creation metrics were available, 0 = false, 1 = true
# TYPE plugin_zpool_creation_metrics_available_boolean gauge
plugin_zpool_creation_metrics_available_boolean 1
# HELP plugin_zpool_creation_metrics_cached_boolean Whether plugin_zpool_creation metrics came from cache, 0 = false, 1 = true
# TYPE plugin_zpool_creation_metrics_cached_boolean gauge
plugin_zpool_creation_metrics_cached_boolean 0
# HELP plugin_zpool_creation_metrics_timer_seconds How long it took to gather the plugin_zpool_creation metrics
# TYPE plugin_zpool_creation_metrics_timer_seconds gauge
plugin_zpool_creation_metrics_timer_seconds 0.112458814
# HELP plugin_zpool_creation_timestamp_seconds Number of seconds after UNIX epoch when the system's zpool was created.
# TYPE plugin_zpool_creation_timestamp_seconds gauge
plugin_zpool_creation_timestamp_seconds 1546505749
```

in which case the plugin is working.
