# Setting up DHCP

This is basically a copy of some text notes I did several years ago. I'll do some basic markdown, but this will require revision later.

The dhcpd daemon is handled as a service by RHEL. So, to start it on a host, execute "service dhcpd start." As with any service, "stop" and "restart" are also valid commands. And, as with any service "chkconfig dhcpd on" will start the service at boot time.
 
 Actual DHCP configuration is handled by `/etc/dhcp/dhcpd.conf`. The man page for the [configuration file][dhcpdconf] is heavy reading, but I've found nothing better for explaining all of the potential functionality of dhcp. The easiest way to describe how it is set up a sample `dhcpd.conf` file.

[dhcpdconf]: http://www.daemon-systems.org/man/dhcpd.conf.5.html


## Global settings

First, we start with the global settings. The two "allows" tell dhcpd to serve the "next-server" and "filename" information to requesting hosts.

```
ddns-update-style interim;
allow booting;
allow bootp;
update-static-leases on; 

set vendorclass = option vendor-class-identifier;
```

## Subnets

Then, we identify our primary subnet. This example is a simple class C subnet.

```
subnet 192.168.0.0 netmask 255.255.255.0
{

```


And these subnet and netmask values would combine two class C subnets, `192.168.2.0` and `192.168.3.0` into a single, 510-host network. The network number would be `192.168.2.0` and the broadcast address would be `192.168.3.255`. (And, depending on your convention, the default router for the subnet would usually be either `192.168.2.1` or `192.168.3.254`.)

```
subnet 192.168.2.0 netmask 255.255.254.0
{

```

(What happened to `192.168.1.0`? Here's a hint: it has to do with the limitations of netmasking.)

Let's say that the `192.168.0.0` subnet is only for hosts we already know about. Inside the subnet block (ie. after the opening brace),  we'll start off with the subnet-specific settings. The entry `deny unknown-clients` tells dhcpd that hosts not listed in the `dhcpd.conf` file don't get served IP addresses. If this subnet used address pools (the `dhcpd.conf` keyword is "range"), this would tell dhcpd to only serve out pool addresses to listed MAC addresses. However, for this example, we're going to assign a specific IP address to each MAC address, so pools are an unnecessary security risk.

Following the `deny` keyword are three `option` statements for information that gets passed on to the client hosts on request. The RHEL `dhclient` utility handles writing these options out to the appropriate files for use by their respective services.

The final option, "use-host-decl-names on" tells dhcpd that the hostnames listed here are to be passed back to the client hosts, like the options, to use as their hostnames. RHEL doesn't actually honor this, but other operating systems might. Including this capacity would be particularly useful in setting up new hosts. The new MAC address gets set up here, and all networking information, including the host  name, would be provided to the new host at boot time.

```
  deny unknown-clients;
  option routers 192.168.0.1;
  option domain-name-servers 192.168.0.1, 4.2.2.2;
  option ntp-servers ntp1.example.com, ntp2.example.com;
  default-lease-time 86400; # 1 day
  max-lease-time 604800; # 7 days
  use-host-decl-names on;

```

(Here's another one: why are FQDNs allowed for the `ntp-server`s, but the `routers` and `domain-name-servers` have to be IP addresses? The hint? If you have hostnames for your DNS servers, how do you look up their IP addresses?)


## Groups

Inside a subnet, groups are for clumping a set of hosts that share a common set of specific options. Here, I can specify the order of their domain name searches. The `next-server` and `filename` are information for new hosts being installed via the network. While these entries would typically be common to all groups, having them inside group entries is permitted and simplifies splitting out the PXE install options, should that become necessary. A `dhcpd.conf` file can have groups for example.com, sub1.example.com, sub2.example.com, and sub3.example.com, if that makes sense. Here, they are bundled into a single group and both `sub1` and `sub2` will start their DNS lookups in `sub1`. Alternately, the three `sub2` hosts could be in a different group, allowing you to change the order of the subdomains in the `domain-name` option.

The `group` keyword is all DHCP needs. The comment about the subdomain is solely for administrator readability.

```
  group # sub1.example.com
  {
    option domain-name "sub1.example.com sub2.example.com sub3.example.com example.com";
    next-server 192.168.0.11;
    filename "pxelinux.0";

```

Now, we get to the meat of the `dhcpd.conf` file. The individual `host` settings specify a host by name, identify its MAC address, and assign it an IP address (via a DNS lookup) at boot time. The `dhcpd.conf` file maps MAC addresses to hostnames, and DNS maps hostnames to IP addresses.


```
    host host1.sub1.example.com    {hardware ethernet 01:23:45:67:89:67; fixed-address host1.sub1.example.com;}
    host host2.sub1.example.com    {hardware ethernet 01:23:45:67:89:89; fixed-address host2.sub1.example.com;}
    host host1.sub2.example.com    {hardware ethernet 01:23:45:67:89:ab; fixed-address host1.sub2.example.com;}
    host host2.sub2.example.com    {hardware ethernet 01:23:45:67:89:cd; fixed-address host2.sub2.example.com;}
    host host3.sub2.example.com    {hardware ethernet 01:23:45:67:89:ef; fixed-address host3.sub2.example.com;}
}

```

The keywords `hardware ethernet` should be obvious. At the time of this writing, `ethernet` was the only permitted hardware type specification. The keyword `fixed-address` tells dhcpd to use a specific address, as opposed to assigning one out of a pool.

Okay, so what about setting a range? Let's do that in our other subnet. Here's the entire block:

```
subnet 192.168.2.0 netmask 255.255.254.0
{
  allow unknown-clients;
  option routers 192.168.2.1;
  option domain-name-servers 192.168.2.1, 4.2.2.2;
  option ntp-servers ntp1.example.com, ntp2.example.com;
  default-lease-time 86400; # 1 day
  max-lease-time 604800; # 7 days
  use-host-decl-names on;

  pool
  {
    one-lease-per-client true;
    ping-check true;
    range 192.168.2.51 192.168.3.50;
  }
}

```

The keyword `one-lease-per-client` tells DHCP to track MAC addresses in order to keep MAC and IP addresses matched up as much as possible. This is good for consistency. The `ping-check` keyword tells DHCP to ping the IP address before it is assigned, just to make sure it's not already in use. Finally, the `range` keyword gives the starting and ending IP addresses for the pool, inclusive.

DHCP only requires the one file. After editing it, do `service dhcpd restart` to push the changes to the daemon.


