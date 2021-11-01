# General Notes

## 2021-10-31

### Containerization

I [containerized by DHCP and DNS daemons][211031a], mostly for the
practice. But, I also saw a comment somewhere that containers were
"chroot on steroids." That makes sense. So, let's put both functions
in isolated sandboxes.

I haven't (yet) done anything about securing them. But, that's largely
a case of adding entries to the zone files. I'll add that in when I
get around to it.


### Dynamic Zone Updates

[Here is a Python program][211031b] to dynamically update smaller DNS
zones without having to stop and start `named`.


[211031a]: https://github.com/dafydd2277/dhcpd-bind9
[211031b]: https://zad.readthedocs.io/en/latest/introduction.html


## 2021-07-06

Here's a first pass at DNS over HTTPS: https://wiki.archlinux.org/index.php/DNS_over_HTTPS_servers

