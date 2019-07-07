# Setting Up Remote Hosts


Here is where I had my first problem. As I was following [the
instructions][remote], I only modified the `dumptype` slightly.

[remote]: http://wiki.zmanda.com/index.php/GSWA/Backing_Up_Other_Systems

```bash
cat <<EODUMPTYPE >>/etc/amanda/localdomain/amanda.conf
define dumptype gnutar-remote {
  auth "ssh"
  ssh_keys "/etc/amanda/localdomain/id_ecdsa"
  compress client best
  program "GNUTAR"
}
EODUMPTYPE


cat <<EODISKLIST >>/etc/amanda/localdomain/disklist
remote /etc          gnutar-remote
remote /opt          gnutar-remote
remote /root         gnutar-remote
remote /usr/local    gnutar-remote
remote /var/lib      gnutar-remote
remote /var/local    gnutar-remote
remote /var/log      gnutar-remote
remote /var/named    gnutar-remote
remote /var/opt      gnutar-remote
remote /var/preserve gnutar-remote
remote /var/www      gnutar-remote
EODISKLIST


ssh-keygen \
  -t ecdsa \
  -N '' \
  -b 521 \
  -C 'amandabackup@backupmaster' \
  -f /etc/amanda/localdomain/id_ecdsa
```

I copied the SSH public key over to `remote:/var/lib/amanda`, just as
instructed. However, I couldn't log in. Testing with `ssh -vvvv` didn't
tell me anything useful. I found the clue in
`remote:/var/log/messages`.

```bash
Jul  6 17:48:55 remote setroubleshoot: SELinux is preventing \
/usr/sbin/sshd from read access on the file authorized_keys. For \
complete SELinux messages run: \
sealert -l 1adeaf3c-2467-4ef7-b66a-36ebd56700f2
```

Yes, I run these hosts with SELinux enforcing.

```bash
[root@remote ~]$ getenforce
Enforcing

```


The SELinux report suggested creating a custom module, but that seems
like a bit much. So, I go digging for the `semanage fcontext` of my
`~/.ssh` directory, and then go digging.

```bash
[root@remote ~]# semanage fcontext -l | grep ssh_home_t
/var/lib/[^/]+/\.ssh(/.*)?                all files  system_u:object_r:ssh_home_t:s0 
/root/\.ssh(/.*)?                         all files  system_u:object_r:ssh_home_t:s0 
/var/lib/one/\.ssh(/.*)?                  all files  system_u:object_r:ssh_home_t:s0 
/var/lib/pgsql/\.ssh(/.*)?                all files  system_u:object_r:ssh_home_t:s0 
/var/lib/openshift/[^/]+/\.ssh(/.*)?      all files  system_u:object_r:ssh_home_t:s0 
/var/lib/amanda/\.ssh(/.*)?               all files  system_u:object_r:ssh_home_t:s0 
/var/lib/stickshift/[^/]+/\.ssh(/.*)?     all files  system_u:object_r:ssh_home_t:s0 
/var/lib/gitolite/\.ssh(/.*)?             all files  system_u:object_r:ssh_home_t:s0 
/var/lib/nocpulse/\.ssh(/.*)?             all files  system_u:object_r:ssh_home_t:s0 
/var/lib/gitolite3/\.ssh(/.*)?            all files  system_u:object_r:ssh_home_t:s0 
/var/lib/openshift/gear/[^/]+/\.ssh(/.*)? all files  system_u:object_r:ssh_home_t:s0 
/root/\.shosts                            all files  system_u:object_r:ssh_home_t:s0 
/home/[^/]+/\.ssh(/.*)?                   all files  unconfined_u:object_r:ssh_home_t:s0 
/home/[^/]+/\.ansible/cp/.*               socket     unconfined_u:object_r:ssh_home_t:s0 
/home/[^/]+/\.shosts                      all files  unconfined_u:object_r:ssh_home_t:s0 

```

So, what I need to do is put the ssh key for amanda in
`/var/lib/amanda/.ssh/authorized_keys`, not in the location given in
the example.

```bash
mkdir /var/lib/amanda/.ssh

cat <<EOPUBKEY >/var/lib/amanda/.ssh/authorized_keys
##### Public Key
EOPUBKEY

restorecon -rv /var/lib/amanda

```

And on the backup master:

```bash
sed -i \
  '#^\s*ssh_keys.*#ssh_keys "/var/lib/amanda/.ssh/id_ecdsa"#' \
  /etc/amanda/localhost/amanda.conf

```

So, the disktype section now looks like this.

```bash
define dumptype gnutar-remote {
  auth "ssh"
  ssh_keys "/var/lib/amanda/.ssh/id_ecdsa"
  compress client best
  program "GNUTAR"
}

```

And `su - amandabackup` and `ssh remote` now work.




