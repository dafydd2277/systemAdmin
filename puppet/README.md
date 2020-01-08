# Puppet Code

## 2020-01-07

This is where I'll start sharing sanitized, not-client-specific
versions of the Puppet code I had a hand in. The underlying
assumption is that directories and files will appear in
${PUPPET_CODE_BASE}/site/, and not as an independent module.

Let's start with a `local_firewall` site module that is a pretty
close equivalent to the `iptables` files in
[my firewall section][20200107a]. I don't think they match exactly,
so checking both directories can't hurt.


[20200107a]: https://github.com/dafydd2277/systemAdmin/tree/master/firewall
