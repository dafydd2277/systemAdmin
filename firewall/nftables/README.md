# NFTABLES

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

