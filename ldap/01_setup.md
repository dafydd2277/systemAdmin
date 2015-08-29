# Basic LDAP Configuration

This document will walk you through the steps needed to install [389 Directory Server 9][389ds9] and set strong password hashing.

I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can create a successful 389-DS installation by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[389ds9]: http://www.port389.org/
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html


## Dependencies

These instructions take advantage of bash security features outlined in [BASH-01_secureHistory.md][BASH-01].

[BASH-01]: https://github.com/dafydd2277/systemAdmin/blob/master/BASH-01_secureHistory.md


## References

- [Red Hat Directory Server - Installation Guide][rhds9]

[rhds9]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Installation_Guide/index.html

## Installation considerations.

- In the last few steps, where you actually create a user account in LDAP, you'll note that I give that user a UID of 20001. I strongly recommend UIDs and GIDs for centralized users and groups *start* at a five-digit number. This allows an enormous pool of UIDs and GIDs between 501 and 9999 for local users and groups.
- Which users and groups should be local? Which should be centralized/LDAP?

    My opinion is that interactive, flesh-and-blood users should always be managed via a remote service like LDAP/Kerberos. This, along with [Kerberos-aware NFS][knfs], will allow a user to log in to any controlled host. On the other hand, I prefer to keep "application users" (Those users that actually "own" application binaries and libraries, like `oracle`, `puppet`, or `splunk`) local. That way, those services or applications continue to run even if contact with the LDAP/Kerberos implementation is lost. A significant exception would be those automated users ("service accounts") for automated remote access. Examples would be [Tripwire][] or [UC4][], where an external automation "logs in" to the host. Those should be handled centrally, with privileges defined by sudo.
    
[knfs]: http://sadiquepp.blogspot.com/2009/02/how-to-configure-nfsv4-with-kerberos-in.html
[tripwire]: http://www.tripwire.com/
[UC4]: http://automic.com/

## Install EPEL

EPEL is "Extra Packages for Enterprise Linux." 389-DS lives here. So, step 1 is to incorporate EPEL into your yum repository lists. You can [get the latest "epel-release" RPM][epelRelease] from the EPEL page on the [Fedora Project wiki][fedoraWiki]. Once you've downloaded the package, put it in an accessible directory, `cd` to that directory, and do a local install.

```bash
yum localinstall ./epel-release*.rpm

yum repolist

```


[epelRelease]: https://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F
[fedoraWiki]: https://fedoraproject.org/wiki/Fedora_Project_Wiki


## Install the packages.

Once the EPEL package is installed, you should be able to download the 389-ds wrapper package. Again, let's just do a `yum install`, instead of fussing with which version of 389-ds might already be installed.

```bash
yum install 389-ds-base 389-admin 389-adminutil

```

## Create a local settings file.


Create a sysconfig file to keep track of local customization. One item I'll point out to you: my `${ROOTDN}` is not actually "`cn=Directory Manager`." If I'm going to publicize the name of my Directory Manager, it should be something not the default, right? Similarly, if you're setting up your 389-ds for Production service, consider changing the name of your RootDN.

```bash
df_ds_sysconfig=/etc/sysconfig/local-ds
export df_ds_sysconfig

cat <<EOT >${df_ds_sysconfig}
d_389ds_root=/root/.389ds
export d_389ds_root

df_dsadmin_passphrase=\${d_389ds_root}/dsadmin_passphrase.txt
df_dirmgr_passphrase=\${d_389ds_root}/dirmgr_passphrase.txt
df_389ds_setup=\${d_389ds_root}/setup-ds-admin.inf

export df_dsadmin_passphrase df_dirmgr_passphrase df_389ds_setup

# Directory Server Instance Name: slapd-\${s_instance}
s_instance="ds01"
s_basedn="dc=example,dc=com"
s_domain="example.com"
s_dirmgr="cn=Directory Manager"

export s_instance s_basedn s_domain s_dirmgr

d_admin_etc=/etc/dirsrv/admin-serv
d_instance_etc=/etc/dirsrv/slapd-\${s_instance}
d_instance_usr=/usr/lib64/dirsrv/slapd-\${s_instance}
d_instance_var=/var/lib/dirsrv/slapd-\${s_instance}

export d_admin_etc d_instance_etc d_instance_usr d_instance_var

EOT

```

([Why do I use dollar-parentheses instead of backticks in bash command expansion like `$(hostname -s)`?][faq082])

Then, call the file to load the variables into the shell.

```bash
. ${df_ds_sysconfig}

```

[faq082]: http://mywiki.wooledge.org/BashFAQ/082


## Configure system files.

389-ds needs to have two system files modified:

- In `/etc/sysctl.conf`, `net.ipv4.tcp_keepalive_time` needs to be 300 seconds are greater.
- Add the file `/etc/security/limits.d/nobody`, with `soft nofile` and `hard nofile` entries for `nobody` set to at least 8192.

Here's a [bash][tldpbash] script automation to handle the settings changes.

```bash
egrep "^[!#]*net.ipv4.tcp_keepalive_time = 300" /etc/sysctl.conf >/dev/null 2>&1
if [ $? -ne 0 ]
then
  cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%Y%m%d)
  grep "net.ipv4.tcp_keepalive_time" /etc/sysctl.conf >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo -e "\n\n# Modifications for Directory Server." >>/etc/sysctl.conf
    echo -e "net.ipv4.tcp_keepalive_time = 300" >>/etc/sysctl.conf
  else
    sed -i "s/^[!#]*net\.ipv4\.tcp_keepalive_time.*/net.ipv4.tcp_keepalive_time = 300/g" /etc/sysctl.conf
  fi
fi

cat <<EOT >/etc/security/limits.d/nobody
nobody soft nofiles 8192
nobody hard nofiles 8192
EOT
 
```

[tldpbash]: http://www.tldp.org/LDP/Bash-Beginners-Guide/html/index.html


## Set up the `.inf` file.

The 389-ds `setup-ds-admin.pl` setup script can take an answer file in `.inf` format. The file is described in [Section 4.5][sec45] for the RHDS Installation Guide. This is particularly handy in development situations, where you can blow away your 389-ds installation and recreate it. The options are described in [Section 1.4][sec14].

Alternately, you can use `setup-ds-admin.pl --keepcache` to save a `.inf` file from the first time you execute the script. See Table 1.1 in [Section 1.3][sec13] of the RHDS Installation Guide.

**IMPORTANT**: clear-text passwords are kept in this file. So, let's keep it in `root`'s home directory, along with the passphrase files, themselves.

One other trick: you'll note that I'm again using `sha1sum` to create random 40-character passphrases from random 2048-character strings generated by `/dev/urandom`. This is still better security, but using this method will be hard if you just to run `setup-ds-admin.pl` by hand. My suggestion for that case is that you have a second terminal window open to allow you to copy and paste the passphrases into the appropriate places. If you go this route, the contents of `${df_dsadmin_passphrase}` are requested first by `setup-ds-admin.pl`, followed by the contents of `${df_dirmgr_passphrase}`.

(Having said that, one limitation of `sha1sum` is that it's a string of 40 hexadecimal characters. I've actually stopped using it, in favor of using a larger set of `tr`anslation characters than `A-Za-z0-9` and combining several `head -c` and `tail -c` trims of that initial output. My password strings are not 40 characters, and are not limited to `0-9a-f`.)

```bash
mkdir --mode 700 --parents ${d_389ds_root}

tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${df_dsadmin_passphrase}
chown root:root ${df_dsadmin_passphrase}
chmod 0400 ${df_dsadmin_passphrase}


tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${df_dirmgr_passphrase}
chown root:root ${df_dirmgr_passphrase}
chmod 0400 ${df_dirmgr_passphrase}

```

These files will be used repeatedly, later on. So, they're separate. Here's the rest of the manually created .inf file.

```bash
s_admin_user="admin"
s_server_ip=111.111.111.111
export s_admin_user s_server_ip

cat <<EOT >${df_389ds_setup}
[General] 
FullMachineName= ${HOSTNAME}.${s_domain}
SuiteSpotUserID= nobody 
SuiteSpotGroup= nobody 
AdminDomain= ${s_domain}
ConfigDirectoryAdminID= ${s_admin_user}
ConfigDirectoryAdminPwd= $(cat ${df_dsadmin_passphrase})
ConfigDirectoryLdapURL= ldap://${HOSTNAME}.${s_domain}:389/o=NetscapeRoot 

[slapd] 
SlapdConfigForMC= Yes 
UseExistingMC= 0 
ServerPort= 389 
ServerIdentifier= ${s_instance} 
Suffix= ${s_basedn}
RootDN= ${ROOTDN}
RootDNPwd= $(cat ${df_dirmgr_passphrase})
ds_bename=exampleDB 
AddSampleEntries= No
AddOrgEntries= No

[admin] 
Port= 9830
ServerIpAddress= ${s_server_ip}
ServerAdminID= ${s_admin_user} 
ServerAdminPwd= $(cat ${DS_PASSPHRASE})

EOT

chown root:root ${df_389ds_setup}
chmod 0400 ${df_389ds_setup}

```

[sec13]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Installation_Guide/about-setup-ds-admin.pl.html
[sec14]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Installation_Guide/Preparing_for_a_Directory_Server_Installation-Installation_Overview.html
[sec45]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Installation_Guide/Advanced_Configuration-Silent.html


## Execute the DS setup script.

Now that your system configuration is recorded, execute the startup script. You have several options, here. First, if you chose to use the setup script to create your `.inf` file, execute the setup script like this.

```bash
/usr/sbin/setup-ds-admin.pl --keepcache

```

The resulting `.inf` file will appear in `/tmp`. Don't forget to rename it to `${df_389ds_setup}`!

The second method assumes you have a `.inf` and still want to iterate through the script questions. Except for the passwords, all settings from the `.inf` file will show up as the default values. The passwords will need to be re-entered by hand.

```bash
/usr/sbin/setup-ds-admin.pl --file=${df_389ds_setup}

```

The third method is to execute the `.inf` file without direct user input. Here, the passwords given in the `.inf` file are used.

```bash
/usr/sbin/setup-ds-admin.pl --file=${df_389ds_setup} --silent

```


## Clean up from the setup script.

You might have noted that I set `AddOrgEntries` to "No" in the `.inf` file. We can add our Organizational Units by hand. The setup script still gives us a bunch of default groups and a `People` OU that we don't need.

```bash
 ldapmodify -v -x -h localhost -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: ou=Special Users,${s_basedn}
changetype: delete

dn: cn=Accounting Managers,ou=Groups,${s_basedn}
changetype: delete

dn: cn=HR Managers,ou=Groups,${s_basedn}
changetype: delete

dn: cn=QA Managers,ou=Groups,${s_basedn}
changetype: delete

dn: cn=PD Managers,ou=Groups,${s_basedn}
changetype: delete

dn: ou=Groups,${s_basedn}
changetype: delete

dn: ou=People,${s_basedn}
changetype: delete

dn: ou=users,${s_basedn}
changeType: add
objectClass: top
objectClass: organizationalunit
ou: users

dn: ou=groups,${s_basedn}
changeType: add
objectClass: top
objectClass: organizationalunit
ou: groups

EOT

```

## Set up strong password hashes and restart the service.

Here's the initial password hashing scheme, "out of the box."

```bash
 ldapsearch \
-v \
-H ldap://localhost:389 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "cn=config" \
-s base \
passwordStorageScheme

```

You should have received a bunch of text. The key line is `passwordStorageScheme: SSHA`. This means the default password hashing scheme is Salted SHA, which uses 140 bits. (See [Section 3.1.1.162][sec311162].) We'll change that to Salted SHA256, just to make things harder on crackers. Here's the command to do that.

```bash
 ldapmodify -v -x -h localhost -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: cn=config
changeType: modify
replace: passwordStorageScheme
passwordStorageScheme: SSHA256

EOT

```

[sec311162]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Configuration_Command_and_File_Reference/Core_Server_Configuration_Reference.html#cnconfig


## Add a User

Here, we'll add a user to the LDAP database, then add two groups, listing that user as a member. In the next section, we'll then query for that user, to verify he was correctly added.

```bash
 ldapmodify -v -x -H ldap://localhost:389 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: cn=jdoe,ou=users,${s_basedn}
changeType: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetorgperson
objectClass: posixAccount
objectClass: inetUser
cn: jdoe
homeDirectory: /mnt/home/jdoe
uid: jdoe
uidNumber: 20001
gidNumber: 100
givenName: John
sn: Doe
gecos: John X. Doe
displayName: John X. Doe VI
loginShell: /bin/bash

EOT

 ldapmodify -v -x -H ldap://localhost:389 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: cn=wheel,ou=groups,${s_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: wheel
gidNumber: 10
member: cn=jdoe,ou=users,${s_basedn}

EOT

 ldapmodify -v -x -H ldap://localhost:389 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: cn=users,ou=groups,${s_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: users
gidNumber: 100
member: cn=jdoe,ou=users,,${s_basedn}

EOT

```

- Note that I didn't give this user a password. If I want to do so, I would use the `userPassword:` attribute in the user's entry. Directory Server will then encrypt the password according to the SSHA256 encryption scheme we told 389-ds to use. However, I know I'm going to be setting up Kerberos later, and I'll put the password there, instead.
- Note that I don't have to do this as three separate commands. I could leave the starting `ldapmodify` and the ending `EOT`, and remove the `ldapmodify` and `EOT` lines between the commands. That would work just fine.
- And, note that I created a `wheel` group. Be careful with this group in live installations. The `wheel` group is used to identify System Administrators. With a minimally configured `sudo`, all members of `wheel` can gain privileged (`root`) access.


## Verify the new additions.

And, how does our user look?


```bash
 ldapsearch \
-v \
-H ldap://localhost:389 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=users,${s_basedn}"

```

How about the groups?

```bash
 ldapsearch \
-v \
-H ldap://localhost:389 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=groups,${s_basedn}"

```

Once you've verified everything is showing up, your basic installation is complete.


## Blowing it all away

These commands will remove your 389-ds installation. Obviously, you won't want to include them in any automation that creates your Directory Server for you. While you're in development, these commands will come in really handy. Just don't forget to document everything you've done to this point to perform your configuration, including using the `--keepcache` command the first time you run the setup script.

```bash
service dirsrv stop
service dirsrv-admin stop

yum remove 389-ds \
389-admin \
389-admin-console \
389-admin-console-doc \
389-console \
389-ds-base \
389-ds-base-libs \
389-ds-console \
389-ds-console-doc \
389-dsgw \
idm-console-framework

rm -rf /etc/dirsrv \
/var/lib/dirsrv \
/usr/lib64/dirsrv \
/var/log/dirsrv \
/var/run/dirsrv

```


