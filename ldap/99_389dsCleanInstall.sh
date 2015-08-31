#! /bin/bash
set -x
#
# 99_389dsCleanInstall.sh
#
# Here's where I put it all together. I run this script to dump my 389-ds
# installation and reinstall it from scratch. I made one significant change not
# recorded elsewhere in the documentation. In ${df_ds_sysconfig}, I added
# these variables for my local lead user:
#
# s_cn=jdoe
# s_sn=Doe
# s_givenName=John
# s_uidNumber=20001
# s_gidNumber=20001
# s_homeDirectory=/mnt/users/${s_cn}
# s_loginShell="/bin/bash"
# export s_cn s_sn s_givenName s_uidNumber s_gidNumber s_loginShell
#
# You'll find these variables referenced starting on line 193 of this script.
#
# Also, you'll note that I don't do any SSL certificate creation or recreate
# any of the files in /etc/sysconfig/local-*, /root/.ssl, or /root/.389ds.
# That's not the point of this script. This script is only to serve as a way
# to wipe the 389-DS database cleanly, and restore it to a functional state.
#
# Finally, I also added a UID test to verify this script is being run by root
# only.
#

if [ $(id -u) -ne 0 ]
then
  echo "Must be run as root."
  exit 1
fi

df_ds_sysconfig=/etc/sysconfig/local-ds
df_ssl_sysconfig=/etc/sysconfig/local-ssl
export df_ds_sysconfig df_ssl_sysconfig

. ${df_ssl_sysconfig}
. ${df_ds_sysconfig}

service dirsrv stop
service dirsrv-admin stop

yum -y remove 389-ds \
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


yum -y install 389-ds


/usr/sbin/setup-ds-admin.pl --file=${df_389ds_setup} --silent


ldapmodify -x -v -h localhost -c -D "${s_dirmgr}" \
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

dn: cn=config
changetype: modify
replace: passwordStorageScheme
passwordStorageScheme: SSHA256
-
replace: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-ssl-check-hostname
nsslapd-ssl-check-hostname: off
-
replace: nsslapd-certdir
nsslapd-certdir: ${d_nssdb}
-
replace: nsslapd-allow-anonymous-access
nsslapd-allow-anonymous-access: off
-
replace: nsslapd-require-secure-binds
nsslapd-require-secure-binds: on
#-
#replace: nsslapd-listenhost
#nsslapd-listenhost: 127.0.0.1
#-
#replace: nsslapd-securelistenhost
#nsslapd-securelistenhost: ${HOSTNAME}


dn: cn=encryption,cn=config
changetype: modify
replace: nsSSL3
nsSSL3: off
-
replace: nsTLS1
nsTLS1: on
-
replace: nsSSL3Ciphers
nsSSL3Ciphers: -tls_rsa_export1024_with_rc4_56_sha,
 -rsa_rc4_56_sha,
 -tls_rsa_export1024_with_des_cbc_sha,
 -rsa_des_56_sha,
 +tls_rsa_aes_128_sha,
 +tls_dhe_dss_aes_128_sha,
 +tls_dhe_rsa_aes_128_sha,
 +tls_rsa_aes_256_sha,
 +rsa_aes_256_sha,
 +tls_dhe_dss_aes_256_sha,
 +tls_dhe_rsa_aes_256_sha,
 +tls_dhe_dss_1024_rc4_sha,
 +tls_dhe_dss_rc4_128_sha


dn: cn=RSA,cn=encryption,cn=config
changetype: add
objectclass: top
objectclass: nsEncryptionModule
cn: RSA
nsSSLPersonalitySSL: ${s_ds_cert_name}
nsSSLToken: internal (software)
nsSSLActivation: on


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


# This is brutal on incoming connections. I haven't figured it out, yet.
#dn: cn=config
#changetype: modify
#replace: nsslapd-minssf
#nsslapd-minssf: 128
EOT

mkdir --mode 755 --parents ${d_nssdb}

echo "Internal (Software) Token:$(cat ${df_dsadmin_passphrase})" > ${df_ds_pinfile}

chown nobody:nobody ${df_ds_pinfile}
chmod 0400 ${df_ds_pinfile}

/usr/bin/certutil -A \
-d ${s_sql_prefix}${d_nssdb} \
-f ${df_dsadmin_passphrase} \
-n "${s_ca_name}" \
-t CT,C,C \
-a \
-i ${df_ca_cert}

/usr/bin/pk12util -i ${df_host_p12} \
-w ${df_dsadmin_passphrase} \
-d ${s_sql_prefix}${d_nssdb} \
-k ${df_dsadmin_passphrase}

/usr/bin/certutil -M \
-d ${s_sql_prefix}${d_nssdb} \
-f ${df_dsadmin_passphrase} \
-n "${s_ds_cert_name}" \
-t Pu,Pu,Pu \
-5 sslClient \
-5 sslServer

/usr/bin/certutil -K -d ${s_sql_prefix}${d_nssdb} -f ${df_dsadmin_passphrase}

/usr/bin/certutil -L -d ${s_sql_prefix}${d_nssdb} -f ${df_dsadmin_passphrase}

/usr/bin/certutil -V \
-d ${s_sql_prefix}${d_nssdb} \
-f ${df_dsadmin_passphrase} \
-n "${s_ds_cert_name}" \
-e \
-u V

chown nobody:nobody ${d_nssdb}
chown nobody:nobody ${d_nssdb}/*

# Make sure the client side files have the correct passwords. (Also a memory
# jog to make sure the client files are correct in general!)

s_date=$(date +%Y%m%d)

sed --in-place=.${s_date} "/^ldap_default_authtok/ c\
ldap_default_authtok = $(cat ${df_svcAuthenticator_passphrase})" /etc/sssd/sssd.conf

sed --in-place=.${s_date} "/^TLS_CACERTDIR/ c\
TLS_CACERTDIR /etc/pki/tls/certs" /etc/openldap/ldap.conf

sed --in-place "/^URI/ c\
URI ldaps://localhost:636" /etc/openldap/ldap.conf

sed --in-place "/^BASE/ c\
BASE ${s_basedn}" /etc/openldap/ldap.conf

sed --in-place=.${s_date} "/^binddn/ c\
binddn cn=svcSUDO,ou=serviceAccounts,dc=localdomain" /etc/sudo-ldap.conf

sed --in-place "/^bindpw/ c\
bindpw $(cat ${df_svcSUDO_passphrase})" /etc/sudo-ldap.conf

sed --in-place "/^uri/ c\
uri ldaps://localhost:636" /etc/sudo-ldap.conf


# Restart the services so the first set of ldapmodify entries can be started.

service dirsrv stop

service dirsrv-admin restart

service dirsrv start


# And make the actual working entries.

ldapmodify -v -H ldaps://localhost:636 -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
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

dn: cn=${s_cn},ou=users,${s_basedn}
changeType: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetorgperson
objectClass: posixAccount
objectClass: inetUser
cn: ${s_cn}
homeDirectory: ${s_homeDirectory}
uid: ${s_cn}
uidNumber: ${s_uidNumber}
gidNumber: ${s_uidNumber}
givenName: ${s_givenName}
sn: ${s_sn}
gecos: ${s_givenName} ${s_sn}
displayName: ${s_givenName} ${s_sn}
loginShell: ${s_loginShell}

dn: cn=${s_cn},ou=groups,${s_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: ${s_cn}
gidNumber: ${s_uidNumber}
member: cn=${s_cn},ou=users,${s_basedn}

dn: cn=wheel,ou=groups,${s_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: wheel
gidNumber: 10
member: cn=${s_cn},ou=users,${s_basedn}

dn: cn=users,ou=groups,${s_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: users
gidNumber: 100
member: cn=${s_cn},ou=users,${s_basedn}

# Make our example user a Directory Administrator

dn: cn=Directory Administrators,${s_basedn}
changetype: modify
add: uniqueMember
uniqueMember: cn=${s_cn},ou=users,${s_basedn}

#

dn: ou=serviceAccounts,dc=localdomain
changetype: add
objectClass: organizationalUnit
objectClass: top
ou: serviceAccounts
description: Container for service accounts. Some might have shell access 
 (objectClass: posixUser), most won't.

dn: cn=svcAuthenticator,ou=serviceAccounts,dc=localdomain
changetype: add
objectClass: top
objectClass: person
cn: svcAuthenticator
sn: svcAuthenticator
userPassword: $(cat ${df_svcAuthenticator_passphrase})
description: Service account to allow PAM/SSSD to search the LDAP database.

dn: cn=svcSudo,ou=serviceAccounts,${s_basedn}
changetype: add
objectClass: top
objectClass: person
cn: svcSudo
sn: svcSudo
userPassword: $(cat ${df_svcSUDO_passphrase})
description: Service account to allow SUDO to search the LDAP database.


#

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
EOT

ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=users,${s_basedn}"

ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=Groups,${s_basedn}" \
-s sub

ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=SUDOers,${s_basedn}"

