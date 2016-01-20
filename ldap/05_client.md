# Configure an LDAP client.

I'm not a fan of `authconfig`, because it will modify the files it thinks need modification, not the files that *I* think need modification. That can lead to unexpected results, particularly if I'm copying in system-auth-ac via a [kickstart script][kickstart]. Having said that, thoughtful use of the [authconfig][authconfigks] instruction at the top of the kickstart script might eliminate the need to copy in `ldap.conf`, `nsswitch.conf`, etc.

[kickstart]: https://github.com/dafydd2277/systemAdmin/tree/master/kickstart
[authconfigks]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Installation_Guide/s1-kickstart2-options.html


## References

- [Chapter 12: Configuring Authentication](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/ch-Configuring_Authentication.html)
- [CentOS 6 Linux and nss-pam-ldapd](http://serverfault.com/questions/299855/centos-6-linux-and-nss-pam-ldapd)
- [LDAP authentication with nss-pam-ldapd](http://arthurdejong.org/nss-pam-ldapd/setup)


## SSL

Create an [SSL host certificate][sysAdminSSL01], get it signed, and copy the signed host certificate and a copy of the CA certificate back to `/etc/pki/tls/certs`.

[sysAdminSSL01]: https://github.com/dafydd2277/systemAdmin/blob/master/ssl/01_setup.md


## Authentication



## authconfig

I'm not generally a fan of authconfig, but it is handy for identifying the files that need to change to implement LDAP authentication. Here are the commands I ran:

```
yum -y install pam_ldap

authconfig \
  --savebackup $(date +%Y%m%d)

authconfig \
  --enableldap \
  --enableldapauth \
  --ldapserver=ldaps://${s_ldap_host}/ \
  --ldapbasedn=${s_basedn} \
  --enableldaptls \
  --enablerfc2307bis \
  --ldaploadcacert=${df_client_cert} \
  --disablemkhomedir \
  --update
```

The final authconfig command modified the following files. I found this list by first doing `find / -mtime -1`, identifying a relevant file and using it's timestamp in a grep statement, like this:

```
s_time=<hh:mm>
find / -mtime -1 -ls | grep ${s_time}
```

The following files were modified:

```
/etc/openldap/cacerts/authconfig_downloaded.pem
/etc/openldap/ldap.conf
/etc/pam_ldap.conf
/etc/sssd/sssd.conf
/var/lib/authconfig/last/openldap.conf
/var/lib/authconfig/last/pam_ldap.conf
/var/lib/authconfig/last/sssd.conf
/var/lib/NetworkManager/timestamps
/var/lib/sss/db/cache_default.ldb
/var/lib/sss/db/config.ldb
/var/lib/sss/db/sssd.ldb
/var/lib/sss/mc/group
/var/lib/sss/mc/passwd
```

Additionally, I manually made the following modifications to `/etc/nsswitch.conf`:

```
passwd: files ldap
group:  files ldap
sudoers:  files ldap
```

## sudo-ldap.conf

Note the password you set in LDAP for `svcSUDO`. You'll need to supply that passphrase in `/etc/sudo-ldap.conf`. Here are the entries I set:

I set the following entries in `/etc/sudo_ldap.conf`:

```
binddn cn=svcSUDO,ou=serviceAccounts,${s_basedn}
bindpw [REDACTED]
ssl start_tls
tls_cacertfile ${df_ca_cert}
tls_checkpeer yes
uri ldaps://${s_ldap_host}
sudoers_base ou=SUDOers,${s_basedn}
sudoers_debug 2
```

- If your LDAP server has its own TLS certificate signed by the same CA as your client, `tls_checkpeer` should be fine. 
- Starting with `sudoers_debug 2` gives you a large amount of debugging information as you verify this all works on your first host.


