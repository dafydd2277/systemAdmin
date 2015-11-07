# Configuring NFS.

For NFS, nothing is as good as a thorough read of the man pages. The [nfs(5)][nfs5] man page is my starting point. Have a particular look at the section called "Security Considerations."

[nfs5]: http://linux.die.net/man/5/nfs


## The exports file and the services.

First, start the NFS server services. In CentOS6 it's two commands:

```
service nfs start
service nfs status

```


In CentOS 7, it's three commands:

```
systemctl enable nfs-server
systemctl start nfs-server
systemctl status nfs-server

```


Again, for setting an entry in `/etc/exports`, nothing out there is as good as the man pages. Take a slow read of the [exports(5)][exports5] man page. It will tell you about the format of the file. Then, [exportfs(8)][exportfs8] will tell you about the command and arguments to announce your filesystem to your network. Here, I'm taking advantage of a variable set when [I created the filesystem][01lvmluks].

```
s_domain=example.com

cat <<EOEXPORTS >>/etc/exports
${s_mount_name}  *.${s_domain}(rw,wdelay,no_subtree_check,mountpoint,sec=sys,secure,root_squash,no_all_squash)

EOEXPORTS

```


Once you have your `/etc/exports` file set, execute `exportfs -s` to see how [rpc.mountd][mountd8] will parse the entry (or entries). Redundant options don't really hurt, but I try to be tidy. Then, you can do `exportfs -a` to tell `rpc.mountd` to export everything in your `/etc/exports` file.

Now, some philosophy: NFS used to have a vulnerability ([CVE-1999-0166][cve19990166], [SCIP 13797][scip13797]) where a System Administrator would export a subdirectory on a filesystem, without exporting the entire filesystem. An attacker could exploit this by mounting the filesystem and changing directories up one level to the parent, which was supposed to be inaccessible. The bug has long been fixed, but the philosophy remains: if you're going to export something, only export whole filesystems. And, create a separate filesystem for every export. With LVM, creating filesystems at need is not terribly difficult, and may save you from some future vulnerability. The original bug did cross filesystem boundaries, but doing so is harder.


[exports5]: http://linux.die.net/man/5/exports
[exportfs8]: http://linux.die.net/man/8/exportfs
[01lvmluks]: https://github.com/dafydd2277/systemAdmin/blob/master/filesystems/01_lvm_and_luks.md
[mountd8]: http://linux.die.net/man/8/mountd
[cve19990166]: https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-1999-0166
[scip13797]: http://www.scip.ch/en/?vuldb.13797

## The fstab entries.

## Automounting.

## NFSv4 and Kerberos.

