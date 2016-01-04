# Securing 389 Directory Server

This document will walk you through the steps needed to secure your [389 Directory Server 9][389ds9] installation.

I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can create a successful RHDS installation by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[389ds9]: http://www.port389.org/
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## Dependencies

- [BASH-01_secureHistory.md][BASH-01] for good bash shell security while you're working with passwords.
- [ldap/01_setup.md][389DS-01] for your basic 389-DS configuration.
- [ldap/02_configureSSL.md][389DS-02] for configuring your installation for SSL.

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md
[389DS-01]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/01_setup.md
[389DS-02]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/01_configureSSL.md


## References

- http://www.openssl.org/
- [Starting the Server with SSL enabled](https://www.centos.org/docs/5/html/CDS/ag/8.0/Managing_SSL-Starting_the_Server_with_SSL_Enabled.html#Starting_the_Server_with_SSL_Enabled-Creating_a_Password_File)
- http://www.port389.org/docs/389ds/howto/howto-ssl.html
- http://www.port389.org/docs/389ds/FAQ/faq.html#converting-an-openssl-certificate-for-use-with-directory-server
- http://www.port389.org/docs/389ds/howto/howto-ssl.html#importing-an-existing-self-sign-keycert-or-3rd-party-cacert
- https://developer.mozilla.org/en-US/docs/NSS_security_tools/certutil
- https://developer.mozilla.org/en-US/docs/NSS_tools_:_pk12util


## Disallow anonymous access.

By default, 389-DS allows anonymous connections to search everything except [`cn=config`][cnconfig]. Passwords are not visible, but all other information on all users can be seen. This is still insecure. So, we need to turn it off. Before we do that, though, we need to create a user for SSS or PAM to use for access. This access doesn't need to be privileged, since the services are accustomed to making anonymous connections. They're not going to need to see password entries, etc.

```bash
df_ds_sysconfig=/etc/sysconfig/local-ds
export df_ds_sysconfig

cat <<"EODS" >>${df_ds_sysconfig}

df_svcAuthenticator_passphrase=${d_389ds_root}/svcAuthenticator_passphrase.txt
export df_svcAuthenticator_passphrase

EODS

. ${df_ds_sysconfig}

tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${df_svcAuthenticator_passphrase}
chown root:root ${df_svcAuthenticator_passphrase}
chmod 0400 ${df_svcAuthenticator_passphrase}


 ldapmodify -v -H ldaps://localhost:636 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOMODIFY
dn: ou=serviceAccounts,${s_basedn}
changetype: add
objectClass: organizationalUnit
objectClass: top
ou: serviceAccounts
description: Container for service accounts. Some will have shell access 
 (objectClass: posixUser), most won't.

dn: cn=svcAuthenticator,ou=serviceAccounts,${s_basedn}
changetype: add
objectClass: top
objectClass: person
cn: svcAuthenticator
sn: svcAuthenticator
userPassword: $(cat ${df_svcAuthenticator_passphrase})
description: Service account to allow PAM/SSS to search the LDAP database.
EOMODIFY

```

Next, let's [turn off anonymous access][noanon] and [turn on secure binding][securebind]. The latter requires that all connections be secure. This helps prevent password sniffing off of the network.

```bash
 ldapmodify -v -H ldaps://localhost:636 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOMODIFY
dn: cn=config
changetype: modify
replace: nsslapd-allow-anonymous-access
nsslapd-allow-anonymous-access: off
-
replace: nsslapd-require-secure-binds
nsslapd-require-secure-binds: on
EOMODIFY

```

Invoking this change to anonymity requires a reboot. So, let's do that next.

```bash
service dirsrv restart ${s_instance}
```

The `authconfig` command we ran in [02_configureSSL.md][LDAP-02] is sufficient for this change. We do need to tell PAM and SSS about the new service account though. (If `/etc/pam_ldap.conf` doesn't exist, verify the `pam_ldap` RPM package is installed.)

```bash
sed --in-place=.$(date +%Y%m%d) "s/^base.*/base ${s_basedn}/g" /etc/pam_ldap.conf

sed --in-place "/#binddn.*/ a\
binddn cn=svcAuthenticator,ou=serviceAccounts,${s_basedn}" /etc/pam_ldap.conf

sed --in-place "/#bindpw.*/ a\
bindpw $(cat ${df_svcAuthenticator_passphrase})" /etc/pam_ldap.conf

chmod 640 /etc/pam_ldap.conf*

sed --in-place=.$(date +%Y%m%d) "/; ldap_uri/\
{s/.*/&\nldap_default_bind_dn = cn=svcAuthenticator,ou=serviceAccounts,\
${s_basedn}/;:a;n;ba}" /etc/sssd/sssd.conf

sed --in-place "/^ldap_default_bind_dn.*/ a\
ldap_default_authtok = $(cat ${df_svcAuthenticator_passphrase})" /etc/sssd/sssd.conf

```

(See [this stackexchange question][sedappend] for more information on the first sed command on `sssd.conf`. It appends `ldap_default_bind_dn` after the first match of `ldap_uri` *only*.)

(While we're editing `/etc/sssd/sssd.conf`, I'll share the tidbit of adding `debug_level = 0x01F0` to your `[domain/default]` section to run logging up to the maximum. The log file will be `/var/log/sssd/sssd_default.log`.)


[LDAP-02]: https://github.com/dafydd2277/systemAdmin/blob/master/ldap/02_configureSSL.md
[noanon]: http://www.port389.org/docs/389ds/FAQ/anonymous-access-switch.html
[securebind]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/8.2/html/Deployment_Guide/Designing_a_Secure_Directory-Selecting_Appropriate_Authentication_Methods.html
[cnconfig]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Configuration_Command_and_File_Reference/Core_Server_Configuration_Reference.html#cnconfig
[sedappend]: http://stackoverflow.com/questions/18999798/sed-append-after-first-match


## Listen only on secure port 636, and listen only for internal connections.

If your 389-DS instance is on a system with multiple interfaces, you can set it to only listen to one of those interfaces. This is useful for limiting access to inside a firewall, or for hosting multiple instances on different interfaces. 

Combining this with `nsslapd-require-secure-binds`, above, pretty much ensures that only SSL connections will be allowed.

```bash
 ldapmodify -H ldaps://localhost:636 \
-v -c \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOMODIFY
dn: cn=config
changetype: modify
replace: nsslapd-listenhost
nsslapd-listenhost: 127.0.0.1
-
replace: nsslapd-securelistenhost
nsslapd-securelistenhost: $(hostname -f)
-
replace: nsslapd-minssf
nsslapd-minssf: 96
EOMODIFY

```

I strongly recommend examining the [`cn=config`][cnconfig] settings for these entries.

