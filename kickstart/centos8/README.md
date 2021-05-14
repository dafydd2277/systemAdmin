# CentOS 8 Kickstart

This directory has three parts.

First, `single.ks.cfg` is an exemplar all-in-one kickstart file for
CentOS 8.

Second, the remaining `*.cfg` files demonstrate how that kickstart
file may be broken up using the `include` command to allow
combinations of configuration elements for a specific `hostname` along
with generic elements that could apply to any host in your enterprise.
For those, start by looking at `hostname/ks.cfg` for how the `include`
commands can be used to combine generic and host-specific kickstart
commands.

Finally, `isoBuilder.sh` will take a monolithic kickstart file and
build it into an ISO image. I have commentary in it that should help
sort out what it does.

