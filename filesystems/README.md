# Notes on Filesystems
<!-- ----1----5----2----5----3----5----4----5----5----6----5----7----5- -->
The individual files have notes on their topics, for now.


## 2021-03-18

Extending a logical volume, as root. Run with the `--test` argument first,
to make sure everything works. Then, re-execute without that argument. Look at
the man pages for details. The `fc` bash built-in is handing for editing the
commands for the second pass.

```bash
pvcreate --verbose \
  --test \
  /dev/sdc

vgextend --verbose \
  --test \
  vgRoot \
  /dev/sdc

lvextend --size +12g \
  --resizefs \
  --verbose \
  --test \
  vgRoot/home

```


## 2020-06-29

[Mounting a Remote Filesystem via SSH][sshfs] could be a simpler
alternative to NFSv4 encryption over the wire. It could also be used as a
supplement to a user's home directory, with individual SSH keys for
identity verification. (I don't know if SSHFS is subject to the old [NFSv3
directory traversal flaw][cve19990166]. Mitigation of this flaw [MUST][]
be verified before implementing SSHFS.)

[sshfs]: https://www.digitalocean.com/community/tutorials/how-to-use-sshfs-to-mount-remote-file-systems-over-ssh
[cve19990166]: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-1999-0166
[MUST]: https://tools.ietf.org/html/rfc2119
