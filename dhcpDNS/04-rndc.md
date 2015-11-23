# Using rndc and nsupdate.

If you're using dynamic DNS, making manual changes to your zone files can become dangerous. What do you have control over? What is controlled by the automated updates coming from DHCP. One way around this is to use `[rndc(8)][rndc8]`.

[rndc8]: http://linux.die.net/man/8/rndc

## Set up a configuration file.

First, for the most secure configuration, you should only use `rndc` from your master DNS server. Allowing `rndc` to be run from other hosts increases your potential attack surface. The configuration I'm building here comes under this assumption.

The default configuration file is [rndc.conf(5)][rndc.conf5], which is located at `/etc/rndc.conf` by default. To make things easy, I'm going to use [rndc-confgen[8][rndc-confgen8] to automatically generate the file along with a customized access key. The file will include commented sections that I will add to `/var/named/chroot/etc/named.conf`. (I'll let you decide if this is my actual key or not... Also, I'm including the `time` command just to see how long it takes...)

```
time rndc-confgen -b 512

# Start of rndc.conf
key "rndc-key" {
  algorithm hmac-md5;
  secret "2GPFXKZOPVelmqTOWRsrKS10VG06vO+jVgNHOH5XXR3NdEu6wLSB0Ul5O/BoJi+w3XmKF3tN/6g8V6eC/NtF/A==";
};

options {
  default-key "rndc-key";
  default-server 127.0.0.1;
  default-port 953;
};
# End of rndc.conf

# Use with the following in named.conf, adjusting the allow list as needed:
# key "rndc-key" {
#   algorithm hmac-md5;
#   secret "2GPFXKZOPVelmqTOWRsrKS10VG06vO+jVgNHOH5XXR3NdEu6wLSB0Ul5O/BoJi+w3XmKF3tN/6g8V6eC/NtF/A==";
# };
# 
# controls {
#   inet 127.0.0.1 port 953
#     allow { 127.0.0.1; } keys { "rndc-key"; };
# };
# End of named.conf

real  8m13.049s
user  0m0.000s
sys 0m0.005s

```

So, copy the first section into `/etc/rndc.conf` and copy the second section, uncommented, into `/var/named/chroot/etc/named.conf`. Remove any previous section there. Finally, reset and restart.

```
rm -f /etc/rndc.key
chmod 0640 /etc/rndc.conf

service named restart

```

[rndc.conf5]: http://linux.die.net/man/5/rndc.conf
[rndc-confgen8]: http://linux.die.net/man/8/rndc-confgen

## Setting up nsupdate.

NS
## Managing your DNS records.

`rndc` is a dynamic controller for DNS, but it doesn't handle individual entries. For that, we need `[nsupdate(8)[nsupdate8]`. However, we need to use both of them together to keep the DNS records from being corrupted. That starts with the `rndc freeze` command to stop other services from making changes..


```
rndc status
rndc freeze localhost

```

Finally, when we're done, we thaw the host, allowing dynamic modifications to continue.

```
rndc thaw localhost

```

