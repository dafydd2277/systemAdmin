# DRAFT
# Creating Access Controls, Roles, and Service Accounts in 389 Directory Server
 
This document will walk you through the steps needed to set up a service account for PAM in [389 Directory Server 9][389ds9]. We want this account to have extensive access to the OU for the users, but read-only access, at  best, elsewhere in the LDAP database. We're going to set that up by creating an [Access Control List][acl] with that set of privileges. Then, we're going to create a [Role][] that implements those privileges. Finally, we're going to create a [Group][] that owns that role. Finally, we're going to create a service account "user" that is a member of that group.

I have found remarkably little documentation on the mechanics of implementing ACLs and Roles, and how to associate them with Users and Groups. Some of the documentation I have found is high-level discussion of the role of LDAP in [Role Based Access Control][rbac], and how RBAC is a cleaner, more versatile system to implement than [Attribute Based Access Control][abac]. I agree with this. Creating custom attributes to match to privileges on LDAP clients can quickly become ungainly.

So, the system I outline here does this: I create ACLs where needed to identify specific access within the LDAP database. I then create a Role when has that ACL as a privilege. Or, I create a Role just to give a name to a specific Privilege. Then, I can add Users and Groups to that Role.

In this system, Roles and Groups can have a Many/Many relationship. A given Role can belong to Many Groups. A given Group can have Many Roles. Except in extreme cases, I wouldn't add individual Users to Roles. Tracking that would again get messy over time.

Finally, unlike much of the documentation I've seen elsewhere, I'll give you exact `ldapmodify` commands to create these ACLs and Roles and assigning Groups to those Roles. I'll also give `ldapsearch` commands to show that those Roles can be displayed for a particular user.

I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can create a successful RHDS installation by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.


[389ds9]: http://www.port389.org/
[acl]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Managing_Access_Control.html
[role]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management-Using_Roles.html
[group]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management.html
[rbac]: https://en.wikipedia.org/wiki/Role-Based_Access_Control
[abac]: https://en.wikipedia.org/wiki/Attribute_Based_Access_Control
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html


## Dependencies

- [BASH-01_secureHistory.md][BASH-01] for good bash shell security while you're working with passwords.
- [SSL-01_setup.md][SSL-01] to set up your Certificate Signing Request for submission to a Certificate Authority. You'll need the resulting certificate and the CA's signing certificate. Optionally, you can also go through [SSL-02_setupCA.md][SSL-02] to set up your own Certificate Authority
- [ldap/01_setup.md][389DS-01] for your basic 389-DS configuration.
- [ldap/02_configureSSL.md][389DS-02] for your 389-DS SSL configuration.

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md
[SSL-01]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-01_setup.md
[SSL-02]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-02_setupCA.md
[389DS-01]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/01_setup.md
[389DS-02]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/02_configureSSL.md


## References

- [RHDS9 Advanced Entry Management][rhds9-aem]
- [RHDS9 Using Roles][rhds9-roles]
- [RHDS9 Access Control][rhds9-acl]
- At the level of complexity we're getting into, having [LDAP for Rocket Scientists][ldap-rs] in your pocket is a good idea, despite it not being specific to 389-DS.


[rhds9-aem]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management.html
[rhds9-roles]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management-Using_Roles.html
[rhds9-acl]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Managing_Access_Control.html
[ldap-rs]: http://www.zytrax.com/books/ldap/


## The Basics

First, let's export our configuration variables.

```bash
df_ds_sysconfig=/etc/sysconfig/local-ds
export df_ds_sysconfig

. ${df_ds_sysconfig}

```


## Outlining the ACL.

What do we want to set our ACL for? We're trying to create a "user" for PAM on the clients to use to Authenticate and Authorize users. Additionally, PAM can change password and other settings on behalf of those users. So, the authentication user needs significant access to `ou=users` and `ou=groups`, but not much access elsewhere. Let's try this:

```bash
aci: (target="ldap:///ou=users,${s_basedn}")(version 3.0; acl "userAuth"; allow (read,write,search,compare)    )
```

## Adding the roles OU.

Now, create the container OU and our Authentication/Authorization role, as per [Section 6.2.3.2][sec6232] of the Administration Guide. (Note my `description` of the `auth` role. By starting the second line with a space, I tell 389-DS that this is a continuation of the previous line. This is an [LDIF][] standard.

```bash
 ldapmodify -x -H ldap://localhost:389 -c -D "cn=Directory Manager" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: ou=roles,${s_basedn}
changetype: add
objectClass: top
objectClass: organizationalUnit
ou=roles

dn: cn=pamAuthenticator,ou=roles,${s_basedn}
changetype: add
objectclass: top
objectclass: LdapSubEntry
objectclass: nsRoleDefinition
objectclass: nsSimpleRoleDefinition
objectclass: nsManagedRoleDefinition
cn=pamAuthenticator
description: This role grants permission to perform Authentication and
 Authorization tasks with LDAP.

EOT

```

[sec6232]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Advanced_Entry_Management-Using_Roles.html
[ldif]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Creating_Directory_Entries-LDIF_Update_Statements.html


## Add the service account container and user.

Now, let's add a new OU for service accounts and a specific Authentication/Authorization account.

```bash
 ldapmodify -x -H ldap://localhost:389 -c -D "cn=Directory Manager" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: ou=serviceAccounts,${s_basedn}
changetype: add
objectClass: top
objectClass: organizationalUnit
ou=serviceAccounts
description: Container for no-login service accounts.

dn: cn=Authenticator,ou=serviceAccounts,${s_basedn}
changetype: add
objectClass: person
objectClass: organizationalPerson
objectClass: inetorgperson
objectClass: inetUser
cn=Authenticator
description: Service account for LDAP/KRB5 Authentication and Authorization.
nsRoleDN: cn=pamAuthenticator,ou=roles,${s_basedn}
userPassword: ${SVC_AUTH_PASSWORD}

EOT

```




