# manta_gw_ping

## Overview

This is a cmon-agent VM plugin to provide insight into which VMs are having
network problems so severe that they are unable to ping their own gateways. This
is an unfortunate thing to need to check but we've been bitten by this in
production.

It loads the default gateway for the zone and the exits if:

 * the VM has no default gateway
 * the VM is not running (this should not happen as cmon-agent does not run when
   it sees a VM is stopped, but this is an extra layer of protection)
 * the `route` command used to get the gateway IP outputs anything on
   stdout/stderr other than an IP address

It then attempts to run:

```
/usr/sbin/ping $gateway 1
```

in the zone through `zlogin` where `$gateway` is the gateway IP determined
above.

Due to unfortunate behavior of SmartOS `/usr/sbin/ping` it's not possible to use
a timeout while also gathering the response time, so this plugin only returns
whether the gateway was reachable or not.

When the plugin runs successfully, it will provide the metrics that look  like:

```
# /opt/custom/cmon/vm-plugins/manta_gw_ping $(vmadm lookup alias=imgapi0)
ttl	option	300
reachable	gauge	0	Indicates whether the default gw is reachable via ICMP ping (1) or not (0).
#
```

when the gateway is unreachable, and:

```
# /opt/custom/cmon/vm-plugins/manta_gw_ping $(vmadm lookup alias=imgapi0)
ttl	option	300
reachable	gauge	1	Indicates whether the default gw is reachable via ICMP ping (1) or not (0).
#
```

when the gateway is pinged successfully.


## Installation

See ["Plugins" section in cmon-agent's README.md](https://github.com/joyent/triton-cmon-agent/blob/master/docs/README.md#plugins).
But basically you want to create a /opt/custom/cmon/vm-plugins/ directory and
install the `manta_gw_ping` binary to it making sure to set it executable. Once
the binary is in place and the permissions are set correctly, it should be used
immediately when CMON is next queried for any zone on the system.

To test that you have installed correctly you can run (on the CN where this is
installed):

```
curl -sS http://<ADMIN_IP>:9163/v1/<VM_UUID>/metrics | grep manta_gw_ping
```

replacing `<ADMIN_IP>` with the admin IP of your CN and replacing `<VM_UUID>`
with the UUID of your target zone. If you do this you should see output that
looks something like:

```
# HELP plugin_manta_gw_ping_metrics_available_boolean Whether plugin_manta_gw_ping metrics were available, 0 = false, 1 = true
# TYPE plugin_manta_gw_ping_metrics_available_boolean gauge
plugin_manta_gw_ping_metrics_available_boolean 1
# HELP plugin_manta_gw_ping_metrics_cached_boolean Whether plugin_manta_gw_ping metrics came from cache, 0 = false, 1 = true
# TYPE plugin_manta_gw_ping_metrics_cached_boolean gauge
plugin_manta_gw_ping_metrics_cached_boolean 0
# HELP plugin_manta_gw_ping_metrics_timer_seconds How long it took to gather the plugin_manta_gw_ping metrics
# TYPE plugin_manta_gw_ping_metrics_timer_seconds gauge
plugin_manta_gw_ping_metrics_timer_seconds 0.054358065
# HELP plugin_manta_gw_ping_reachable Indicates whether the default gw is reachable via ICMP ping (1) or not (0).
# TYPE plugin_manta_gw_ping_reachable gauge
plugin_manta_gw_ping_reachable 1
```

in which case the plugin is working.

If you do not see this, there should be something in the log at:

```
/var/svc/log/smartdc-agent-cmon-agent\:default.log
```
```

to help you figure out what's wrong.
