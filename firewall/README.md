# Firewall Scripting

My first script, `firewall.sh`, was created out of my need to automate
the installation of a firewall on a NAT gateway. It's a big block of
ugly, but it does what it needs to do.

The newer scripts, `prefix.sh`, `body.sh`, and `suffix.sh` were created
to handle the problem of host-based firewalls on individual hosts
within the enterprise. Most of these hosts only have a single
interface, and most of these hosts have a single, well defined job. So,
I wrote a central script, here called `body.sh`, that contains the
custom `iptables` rules for a specific server type, and I have
`body.sh` call `prefix.sh` and `suffix.sh` for the global rules that
would apply to every host.

## 2020-11-23

I'm starting to look at converting the firewall files from iptables
to nftables. I like the semi-scripting functionality of the files in
`/etc/nftables`. This functionality simplifies configuration through
services like Puppet, where we can just use `file{}` resources to
apply configurations, instead of something more complicated. At least,
I hope. I need to find the execution order of files in
`/etc/nftables`, quickly.

I'm starting with the [nftables wiki][1].

[1]: https://wiki.nftables.org/wiki-nftables/index.php/Main_Page

## 2019-08-03

At long last, here is `body-nat.sh`, the script for handling a firewall
doing Network Address Translation, written in the new
format. The other scripts have gone through and update and some
simplification, as well. Most significantly, with judicious use of
environment variables, as described in `body-nat.sh`, you can source
the script straight from here, and still have it work for your firewall.

