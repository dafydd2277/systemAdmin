# Configuring SUDO for 389-ds

This document will show how to set up sudo privilege management in 389DS.

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## Dependencies

- [BASH-01_secureHistory.md][BASH-01] for good bash shell security while you're working with passwords.
- [SSL-01_setup.md][SSL-01] to set up your Certificate Signing Request for submission to a Certificate Authority. You'll need the resulting certificate and the CA's signing certificate. Optionally, you can also go through [SSL-02_setupCA.md][SSL-02] to set up your own Certificate Authority
- [ldap/01_setup.md][389DS-01] for your basic RHDS configuration.
- [ldap/02_configureSSL.md][389DS-01] for your SSL setup.

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md
[SSL-01]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-01_setup.md
[SSL-02]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-02_setupCA.md
[389DS-01]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/01_setup.md
[389DS-02]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/02_configureSSL.md


## References

- [Red Hat Directory Server - Installation Guide][rhds9]
- http://www.port389.org/docs/389ds/tech-docs.html


[rhds9]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/


## Create the service account for `sudo`

Let's start by giving `sudo` its own service account, like with did with `svcAuthenticator`.

```bash
df_ds_sysconfig=/etc/sysconfig/local-ds
export df_ds_sysconfig

cat <<"EODS" >>${df_ds_sysconfig}
df_svcSUDO_passphrase=${d_389ds_root}/svcSUDO_passphrase.txt
export df_svcSUDO_passphrase

EODS

. ${df_ds_sysconfig}

tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${df_svcSUDO_passphrase}
chown root:root ${df_svcSUDO_passphrase}
chmod 0400 ${df_svcSUDO_passphrase}


 ldapmodify -v -H ldaps://localhost:636 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOMODIFY
dn: cn=svcSUDO,ou=serviceAccounts,${s_basedn}
changetype: add
objectClass: top
objectClass: person
cn: svcSUDO
sn: svcSUDO
userPassword: $(cat ${df_svcSUDO_passphrase})
description: Service account to allow SUDO to search the LDAP database.
EOMODIFY

```


## Add an OU for sudoers

Create the containers.

```bash
 ldapmodify -v -H ldaps://localhost:636 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOMODIFY

dn: ou=SUDOers,${s_basedn}
changeType: add
description: Container for sudoer privileges.
objectClass: organizationalUnit
objectClass: top
ou: SUDOers


dn: cn=defaults,ou=SUDOers,${s_basedn}
changeType: add
cn: defaults
description: Default sudoOptions
objectClass: sudoRole
sudoOption: env_keep+=SSH_AUTH_SOCK


dn: cn=wheel,ou=SUDOers,${s_basedn}
changeType: add
cn: wheel
description: Members of group wheel have access to all privileges.
objectClass: sudoRole
objectClass: top
sudoCommand: ALL
sudoHost: ALL
sudoUser: %wheel

EOMODIFY

```

And verify the change.

```bash
 ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=SUDOers,${s_basedn}" \
-s sub

```


## Client-side modifications.

Every client using LDAP for sudo privileges needs to have these additional modifications.

Configure `/etc/sudo-ldap.conf` to connect to the Directory Server. Don't forget to modify the URI you give the file to refer to your 389-DS server.

```bash
sed --in-place=.$(date +%Y%m%d) "/^#binddn/ a\
binddn cn=svcSUDO,ou=serviceAccounts,${s_basedn}" /etc/sudo-ldap.conf

sed --in-place "/^#bindpw/ a\
bindpw $(cat ${df_svcSUDO_passphrase})" /etc/sudo-ldap.conf


#sed --in-place "/^#tls_cacertfile / a\
#tls_cacertfile /etc/pki/tls/certs" /etc/sudo-ldap.conf

#sed --in-place '/^#tls_checkpeer / a\
#tls_checkpeer yes' /etc/sudo-ldap.conf

sed --in-place '/^#uri / a\
uri ldaps://localhost:636' /etc/sudo-ldap.conf

sed --in-place "/^#sudoers_base / a\
sudoers_base ou=SUDOers,${s_basedn}" /etc/sudo-ldap.conf

```


This last modification to `/etc/sudo-ldap.conf` is optional, but handy for initial debugging. Under normal circumstances, setting the debug value to 0 or 1 is sufficient.

```bash
sed --in-place '/^#sudoers_debug / a\
sudoers_debug 2' /etc/sudo-ldap.conf

```


Then, add a line to `/etc/nsswitch.conf` to look for an LDAP database for sudo.

```bash
sudoers: files ldap

```

(I add the line after the `passwd`/`shadow`/`group` block.)



