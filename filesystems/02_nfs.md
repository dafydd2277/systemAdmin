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
systemctl -l status nfs-server

```


Again, for setting an entry in `/etc/exports`, nothing out there is as good as the man pages. Take a slow read of the [exports(5)][exports5] man page. It will tell you about the format of the file. Then, [exportfs(8)][exportfs8] will tell you about the command and arguments to announce your filesystem to your network. Here, I'm taking advantage of a variable set when [I created the filesystem][01lvmluks].

```
s_domain=<(sub)domain>
d_exports=<exports mount point>

mkdir --parents --mode=0755 ${d_exports}/${s_mount_name}

cat <<EOEXPORTS >>/etc/exports
${s_mount_name}  *.${s_domain}(rw,wdelay,no_subtree_check,mountpoint,sec=sys,secure,root_squash,no_all_squash)

EOEXPORTS

```


Once you have your `/etc/exports` file set, execute `exportfs -s` to see how [rpc.mountd][mountd8] will parse the entry (or entries). Redundant options don't really hurt, but I try to be tidy. Then, you can do `exportfs -a` to tell `rpc.mountd` to export everything in your `/etc/exports` file.

Now, some philosophy: NFS used to have a vulnerability ([CVE-1999-0166][cve19990166], [SCIP 13797][scip13797]) where a System Administrator would export a subdirectory on a filesystem, without exporting the entire filesystem. An attacker could exploit this by mounting the filesystem and changing directories up one level to the parent, which was supposed to be inaccessible. The bug has long been fixed, but the philosophy remains: if you're going to export something, only export whole filesystems. And, create a separate filesystem for every export. With LVM, creating filesystems at need is not terribly difficult, and may save you from some future vulnerability. The original bug did cross filesystem boundaries, but doing so is harder.

Finally, you need to open your firewall to allow clients to connect to these NFS mounts. See [this link][linuxconfig] for configuring CentOS 6. For CentOS 7, [the solution is simpler][stackexchange]:

```
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
firewall-cmd --list-all

```



[exports5]: http://linux.die.net/man/5/exports
[exportfs8]: http://linux.die.net/man/8/exportfs
[01lvmluks]: https://github.com/dafydd2277/systemAdmin/blob/master/filesystems/01_lvm_and_luks.md
[mountd8]: http://linux.die.net/man/8/mountd
[cve19990166]: https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-1999-0166
[scip13797]: http://www.scip.ch/en/?vuldb.13797
[linuxconfig]:  http://linuxconfig.org/how-to-configure-nfs-on-linux
[stackexchange]: http://unix.stackexchange.com/questions/243756/nfs-servers-and-firewalld/243863

## The fstab entries.

I've edited the [fstab(5)][fstab5] file so frequently that I don't really have much in the way of notes. It's all internalized. The only challenges are remembering that the options field ("*fs_mntops*") depends on the filesystem type, and that the two integers on the end are, respectively, for [dump(8)][dump8] frequency ("*fs_freq*"), which virtually no one uses any more, and [fsck(2)][fsck2] ("*fs_passno*") to determine the order in which the filesystems get checked. See the [nfs(5)][nfs5] man page for the options you can include when mounting an NFS filesystem. The [DISA STIG][disastig] requires the options `nodev,nosuid,root_squash` at a minimum.

[fstab5]: http://linux.die.net/man/5/fstab
[dump8]: http://linux.die.net/man/8/dump
[fsck2]: http://linux.die.net/man/2/fsck
[disastig]: http://iase.disa.mil/stigs/Pages/index.aspx



## Automounting.

Once again with the man pages. Here, start off with a good look at [autofs(5)][autofs5] and [auto.master(5)][automaster5]. Also, [Rivald's Blog][rivald] has a simple How-To on specifically automounting home directories.

To start, add an entry like this in `/etc/auto.master`, referencing where you want your automounted home directories to land:

```
cat <<"EOAUTO" >>/etc/auto.master
/home/users    /etc/auto.home

EOAUTO

```

Then, create the `/etc/auto.home` file to point to the NFS server handling your home directories:

```
h_file_server=<FQDN of your NFS server>
d_exported_homedirs=/export/home

cat <<EOHOME >>/etc/auto.home
*    -fstype=nfs,rw,nosuid,soft    ${h_file_server}:${d_exported_homedirs}/&

EOHOME

```

The ampersand (&) on the end is an autofs substitution for user's login name. Call it `${s_user}`. So, if `${s_user}` logs in and the id lookup shows a home directory of /home/users/${s_user}, `autofs(5)` will look in `/etc/auto.master` for `home/users/${s_user}`, find a mapping for `/home/users`, and refer to that mapping file.

The mapping file, `/etc/auto.home`, then tells `autofs(5)` that all entries (`*`) in `/home/users` will get mapped to the exports provided by `${h_file_server}` in the directories `/export/home/${s_user}`. So, mount that home directory automatically with the options and limitations given in the entry.

Once you have the entries in place, restart autofs. In CentOS 6, that's

```
service autofs forcerestart
service autofs status

```

In CentOS 7, that's

```
systemctl enable rpcbind
systemctl start rpcbind
systemctl -l status rpcbind

```

Also, if you have `SELinux` in `enforcing` mode, you'll need to set it to allow NFS-mounted home directories:

```
setsebool -P use_nfs_home_dirs 1
```

[rivald]: http://rivald.blogspot.com/2009/11/automount-home-directories-over-nfs-in.html
[autofs5]: http://linux.die.net/man/5/autofs
[automaster5]: http://linux.die.net/man/5/auto.master


## NFSv4 and Kerberos.

