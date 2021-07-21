# NFTABLES

## 2021-07-21

List a table without translating numeric values, and specifying the
"handle" of each element.

```
nft -na list table filter
```

This produces results something like this:

```
table ip filter { # handle 44
	chain prerouting { # handle 1
		type filter hook prerouting priority -300; policy accept;
		iifname "lo" counter accept # handle 7
		iifname "enp5s5" ip saddr 127.0.0.0/8 counter drop # handle 8
		iifname "enp4s0" ip saddr 127.0.0.0/8 counter drop # handle 9
		iifname "enp5s5" ip daddr 127.0.0.0/8 counter drop # handle 10
		iifname "enp4s0" ip daddr 127.0.0.0/8 counter drop # handle 11
		ip frag-off & 8191 != 0 counter drop # handle 12
		tcp flags & (0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20) == 0x0 counter drop # handle 13
		tcp flags & (0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20) == 0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20 counter drop # handle 14
		ct state 0x8 tcp flags & (0x1 | 0x2 | 0x4 | 0x10) != 0x2 counter drop # handle 15
		ct state 0x2,0x4 counter accept # handle 16
		tcp flags & (0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20) == 0x4 | 0x10 counter packets accept # handle 17
		tcp flags & (0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20) == 0x8 | 0x10 counter accept # handle 18
	}

	chain input { # handle 2
		type filter hook input priority 0; policy drop;
		iifname "$EXT_IF" ip saddr 127.0.0.0/8 counter drop # handle 20
		iifname "$EXT_IF" ip saddr 10.0.0.0/8 counter drop # handle 21
		iifname "$EXT_IF" ip saddr 172.16.0.0/12 counter drop # handle 22
		iifname "$EXT_IF" ip saddr 192.168.0.0/16 counter drop # handle 23
		iifname "$EXT_IF" ip saddr 224.0.0.0/3 counter drop # handle 24
		iifname "$INT_IF" counter accept # handle 25
		iifname "$EXT_IF" tcp dport 22 counter drop # handle 26
```

This allows you to delete a rule,

```
nft delete rule filter input handle 25
```

insert a rule above a handle,

```
nft insert rule filter input position 26 iifname "$INT_IF" counter accept 
```

or after a handle.

```
nft add rule filter input position 24 iifname "$INT_IF" counter accept 
```

[More information here][20210705a].

[20210705a]: https://wiki.nftables.org/wiki-nftables/index.php/Simple_rule_management


## 2021-07-05

1) The nftables firewall also has a [trace mode][ref210705a]. It will
follow matching packets through nftables. In my case, it came in
handy for tracking down why my local system couldn't talk to the on
board container network. Forcing `127.0.0.1` to only appear through the
`lo` interface means that address couldn't also be used by the
container bridge interface. By tracing the path of `127.0.0.1` through
`lo` **and** the bridge interface, I could see requests reach the
container, and replies get dropped on return.
1) Looking at how [packets flow through nftables][ref210705b], let's
move most of the broken packet rules into `prerouting` and save
ourselves a little bit of processing time.

[ref210705a]: https://wiki.nftables.org/wiki-nftables/index.php/Ruleset_debug/tracing
[ref210705b]: https://wiki.nftables.org/wiki-nftables/index.php/Netfilter_hooks


## 2021-07-01

The nftables firewall has a debug mode. For example,

```
nft --debug all add rule nat postrouting ip daddr 192.168.10.3 tcp port 80 dnat 10.10.10.10:80
```

will give you a huge info dump on how nftables sets up the rule.

After experimentation,

```
nft --debug netlink ...
```

gives me reasonable results about how the rule gets crafted internally.
See https://github.com/google/nftables/issues/5,
https://man.archlinux.org/man/nft.8, and
https://wiki.nftables.org/wiki-nftables/index.php/Output_text_modifiers
for more information.


## 2021-05-03

This is initial work on nftables. Most of this will be translation of
the `iptables` scripts in the one-up directory, with some experiments
in splitting a particular chain over several files through the use of
the `include` dynamic.

The `*.main.nft`, `*.pre.nft`, and `*.post.nft` triplets closely match
the `body.sh`, `prefix.sh`, and `suffix.sh` scripts in the parent
directory, in terms of rules set.

The `nat.*.main.nft`, `nat.*.pre.nft`, and `nat.*.post.nft` closely
match `body-nat.sh`, `prefix.sh`, and `suffix.sh`, except the NFT
variable functionality appears in the NFT pre and post script. So, we
can't just use the really generic ones.

To use these files, put a triplet or a `*.nat.nft` with the
corresponding `*.pre.nft` and `*.post.nft` in
`/etc/nftables/`. Then, edit `/etc/sysconfig/nftables` to set the
include line to be something like

```
include "/etc/nftables/<something>.main.nft`
```

or

```
include "/etc/nftables/<something>.nat.nft`
```

then execute

```
systemctl stop iptables
systemctl disable iptables

systemctl stop firewalld
systemctl disable firewalld

systemctl enable nftables
systemctl start nftables
```

You could even do `systemctl mask <service>` instead of `systemctl
disable <service>` if you wanted to be thorough.

Finally, I may get around to turning the boiler plate tables and chains
at the end of each of the `main` rule or command sets into includes of
their own. Not today, though.


## References

- [nftables.org][nftorg]
  - [Configuring Chains][nftChains]
  - [Firewall Example][nftFirewall]
  - [Port Knocking][nftKnockd], if you're into that. (Obscurity !=
  security. I'd rather set up a double-certificate VPN.)
  - [Scripting][nftScripting]
  - [Sets][nftSets]
- [Red Hat - Getting Started with nftables][rhNft]


[nftChains]: https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains
[nftFirewall]: https://wiki.nftables.org/wiki-nftables/index.php/Classic_perimetral_firewall_example
[nftorg]: https://wiki.nftables.org/
[nftKnockd]: https://wiki.nftables.org/wiki-nftables/index.php/Port_knocking_example
[nftScripting]: https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains
[nftSets]: https://wiki.nftables.org/wiki-nftables/index.php/Sets
[rhNft]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/securing_networks/getting-started-with-nftables_securing-networks

