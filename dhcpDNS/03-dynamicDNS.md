# Dynamic DNS

This is a very rough draft. The environment that provided
the documentation for the previous two entries in this directory
had `dDNS` set, but I never wrote in any detail about how it was
set up in the files. So, much of what I relate here is cribbed
from http://www.semicomplete.com/articles/dynamic-dns-with-dhcp/

## Create the key string.

```bash
d_named_root=/root/.named

mkdir --parents ${d_named_root}
chmod 750 ${d_named_root}

cd ${d_named_root}

dnssec-keygen -a hmac-md5 -b 256 -n USER dhcpupdate

# RHEL 7 family
dnssec-keygen -a HMAC-SHA512 -b 512 -n USER -G dhcpupdate

```

(When I came back to this, I found that `dnssec-keygen` hung
when I ran it. Searching for why it might hang, I found a
suggestion to use `-r /dev/urandom` and a counter suggestion that
the `-r` option reduced security. The reason `dnssec-keygen` hangs
is because /dev/random didn't have enough entropy to calculate a
good, secure string. The author of the note that suggested against
`-r` offered "continuing to do work on the host" as an alternate
suggestion. Or, if you have good drivers,
`dd if=/dev/audio of=/dev/random` in a second shell. I've had
reasonable success just perusing a manual page or listing the
contents of various directories.)


## Update DNS

Once the key generation is complete, you will have two
files in `${d_named_root}`, both starting with `Kdhcpupdate`.
You want the random character string that is the final element
of the line in `Kdhcpupdate*.key`. Create a key entry in
`/var/named/chroot/etc/named.conf`.

```
include "/etc/pki/dnssec-keys/dhcpupdate.key";

```

Then, in the file `/var/named/chroot/etc/dhcpupdate.key`,
enter this text block.

```
key "dhcpupdate" {
  algorithm hmac-md5;
  secret "<random string from Kdhcpupdate*.key file>";
};

```

and lock down the file a bit.

```bash
chown named:named /var/named/chroot/etc/dhcpupdate.key
chmod 400 /var/named/chroot/etc/dhcpupdate.key

```


The double quotes are critical in the `secret` attribute line.
Then, add the line `allow-update { key dhcpupdate; };` to the
zone entries which need to be updated on the fly. End with a

```bash
service named restart

```

## nsmodify

Use the nsupdate command to test your dynamic DNS. The example
at the semicomplete.com site uses the zone command, but that isn't
needed any more, and can be confusing. For example, specifying the
zone of "home" and then trying to add a PTR record to the
0.168.192.in-addr.arpa zone will return the NOTZONE error he
mentions.

```bash
nsupdate -d
> server localhost
> key dhcpupdate <random string from Kdhcpupdate*.key file>
> update add 50.0.168.192.in-addr.arpa 600 IN PTR test.localdomain.
> send
> update test.localdomain. 600 IN A 192.168.0.50
> send

```

If you get errors, the semicomplete.com page has some suggestions.
One suggestion is does not have after getting a SERVFAIL is making
sure SELinux will permit named to modify its zone files on the fly.
If you see errors like

```
25-Jan-2015 22:16:08.715 general: error: master/192.168.0.zone.jnl: create: permission denied

```

And you know your SELinux is Enforcing, tell it that named has the right to update its zone files.



## SELinux

See the first note in http://linux.die.net/man/8/named

```bash
semanage boolean --modify --on named_write_master_zones

echo -e "\n\n# Let named update its zones dynamically.\nENABLE_ZONE_WRITE=yes" \
  >> /etc/sysconfig/named

chown named:named /var/named/chroot/var/named/master/*

```

Another trick is to use the output of `nsupdate -d` to figure out what's
going on. One thing I noticed is that the DNS/DHCP key must still be MD5.
Trying SHA256 or SHA512 will fail.


## Update DHCP

First, tell dhcp that it will be sending dynamic updates to DNS.
Place this line in the global options block at the top of your file.

```
ddns-update-style interim;

```


Then, create another `key` statement. This time, you don't need
the quotes around the secret string.

```
include "/etc/pki/dnssec-keys/dhcpupdate.key";

```

Then, acquaint DHCP with the zones it's allowed to update.

```
zone 0.168.192.in-addr.arpa
{
  primary 192.168.0.1;
  key dhcpupdate;
}

zone example.com
{
  primary 192.168.0.1;
  key dhcpupdate;
}

```

## Restart

Finally,

```bash

service restart dhcpd

``` 


