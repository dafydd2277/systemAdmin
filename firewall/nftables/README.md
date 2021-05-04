# NFTABLES

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

Finally, I may get around to turning the boiler plain tables and chains
at the end of each of the `main` rulesets into includes of their own.
Not today, though.

## References

- [nftables.org][nftorg]
  - [Configuring Chains][configChains]
  - [Firewall Example][nftFirewall]
  - [Port Knocking][nftKnockd], if you're into that. (Obscurity !=
  security)
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

