# Additional options for 389-ds

This document will list some additional capabilities that can be built into 389-ds. These are optional, but useful.

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## Dependencies

- [BASH-01_secureHistory.md][BASH-01] for good bash shell security while you're working with passwords.
- [SSL-01_setup.md][SSL-01] to set up your Certificate Signing Request for submission to a Certificate Authority. You'll need the resulting certificate and the CA's signing certificate. Optionally, you can also go through [SSL-02_setupCA.md][SSL-02] to set up your own Certificate Authority
- [ldap/01_setup.md][389DS-01] for your basic RHDS configuration.

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md
[SSL-01]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-01_setup.md
[SSL-02]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-02_setupCA.md
[389DS-01]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/01_setup.md


## References

- [Red Hat Directory Server - Installation Guide][rhds9]
- http://www.port389.org/docs/389ds/tech-docs.html


[rhds9]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/


## Before we do anything.

We going to be referring to the 389 DS local configuration throughout these steps. So, let's make the reference general:

```bash
f_ds_sysconfig=/etc/sysconfig/local-ds
export f_ds_sysconfig
. ${f_ds_sysconfig}

```


## Set up the `MemberOf` plugin.

**WARNING:** If you're using, or going to use, [Multi-Master Replication][mmr], be careful to exclude the `MemberOf` attribute from any replication agreements. Instead, have the masters set their `MemberOf` plugins individually, and using the same rules. See [here][sec6141] for more information on Multi-Master Replication and Fractional Replication.

Before we change the setting, let's see what they look like "out of the box." 

```bash
 ldapsearch \
-v \
-H ldap://localhost:389 \
-D "${l_dirmgr}" \
-y ${f_dirmgr_passphrase} \
-b "cn=MemberOf Plugin,cn=plugins,cn=config"

```

Now, let's make the change and check again.

```bash
 ldapmodify -v -x -h localhost -c -D "${l_dirmgr}" \
-y ${f_dirmgr_passphrase} <<EOT
dn: cn=MemberOf Plugin,cn=plugins,cn=config
changetype: modify
replace: nsslapd-pluginEnabled
nsslapd-pluginEnabled: on
-
replace: memberofgroupattr
memberofgroupattr: member
-
replace: memberofattr
memberofattr: memberOf

EOT


 ldapsearch \
-v \
-H ldap://localhost:389 \
-D "${l_dirmgr}" \
-y ${f_dirmgr_passphrase} \
-b "cn=MemberOf Plugin,cn=plugins,cn=config"

service dirsrv restart

```

So, the service is now running. However, any users already entered won't be updated natively. Fear not! 389DS [comes with a script to update existing users][onemoretech].

```bash
${d_instance_usr}/fixup-memberof.pl \
-v \
-D "${l_dirmgr}" \
-j ${f_dirmgr_passphrase} \
-b ${l_basedn}

```

[mmr]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Managing_Replication-Configuring_Multi_Master_Replication.html
[sec6141]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management.html#groups-cmd-memberof
[onemoretech]: http://onemoretech.wordpress.com/2011/11/23/389rhds-memberof-plugin/

## TODO: Set up the Referential Integrity plugin.

One of the down sides of the MemberOf plugin is that it might not clear the various MemberOf attributes when a group is deleted. The Referential Integrity plugin is designed to verify all MemberOf, [nsRole][], and other attribute DN values actually exist.

[nsRole]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management-Using_Roles.html

