#! /bin/bash
set -x
#
# 99_389dsCleanInstall.sh
#
# Here's where I put it all together. I run this script to dump my 389-ds
# installation and reinstall it from scratch. I made one significant change not
# recorded elsewhere in the documentation. In ${f_ds_sysconfig}, I added
# these variables for my local lead user:
#
# l_cn=jdoe
# l_sn=Doe
# l_givenName=John
# l_uidNumber=20001
# l_gidNumber=20001
# l_homeDirectory=/mnt/users/${l_cn}
# l_loginShell="/bin/bash"
# export l_cn l_sn l_givenName l_uidNumber l_gidNumber l_loginShell
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

f_ds_sysconfig=/etc/sysconfig/local-ds
f_ssl_sysconfig=/etc/sysconfig/local-ssl
export f_ds_sysconfig f_ssl_sysconfig

. ${f_ssl_sysconfig}
. ${f_ds_sysconfig}

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


/usr/sbin/setup-ds-admin.pl --file=${f_389ds_setup} --silent


ldapmodify -x -v -h localhost -c -D "${l_dirmgr}" \
-w $(cat ${f_dirmgr_passphrase}) <<EOT
dn: ou=Special Users,${l_basedn}
changetype: delete

dn: cn=Accounting Managers,ou=Groups,${l_basedn}
changetype: delete

dn: cn=HR Managers,ou=Groups,${l_basedn}
changetype: delete

dn: cn=QA Managers,ou=Groups,${l_basedn}
changetype: delete

dn: cn=PD Managers,ou=Groups,${l_basedn}
changetype: delete

dn: ou=Groups,${l_basedn}
changetype: delete

dn: ou=People,${l_basedn}
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
nsSSLPersonalitySSL: ${l_ds_cert_name}
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

echo "Internal (Software) Token:$(cat ${f_dsadmin_passphrase})" > ${f_ds_pinfile}

chown nobody:nobody ${f_ds_pinfile}
chmod 0400 ${f_ds_pinfile}

/usr/bin/certutil -A \
-d ${l_sql_prefix}${d_nssdb} \
-f ${f_dsadmin_passphrase} \
-n "$l_ca_name" \
-t CT,C,C \
-a \
-i $f_ca_cert

/usr/bin/pk12util -i ${f_host_p12} \
-w ${f_dsadmin_passphrase} \
-d ${l_sql_prefix}${d_nssdb} \
-k ${f_dsadmin_passphrase}

/usr/bin/certutil -M \
-d ${l_sql_prefix}${d_nssdb} \
-f ${f_dsadmin_passphrase} \
-n "${l_ds_cert_name}" \
-t Pu,Pu,Pu \
-5 sslClient \
-5 sslServer

/usr/bin/certutil -K -d ${l_sql_prefix}${d_nssdb} -f ${f_dsadmin_passphrase}

/usr/bin/certutil -L -d ${l_sql_prefix}${d_nssdb} -f ${f_dsadmin_passphrase}

/usr/bin/certutil -V \
-d ${l_sql_prefix}${d_nssdb} \
-f ${f_dsadmin_passphrase} \
-n "${l_ds_cert_name}" \
-e \
-u V

chown nobody:nobody ${d_nssdb}
chown nobody:nobody ${d_nssdb}/*

# Make sure the client side files have the correct passwords. (Also a memory
# jog to make sure the client files are correct in general!)

s_date=$(date +%Y%m%d)

sed --in-place=.${s_date} "/^ldap_default_authtok/ c\
ldap_default_authtok = $(cat ${f_svcAuthenticator_passphrase})" /etc/sssd/sssd.conf

sed --in-place=.${s_date} "/^TLS_CACERTDIR/ c\
TLS_CACERTDIR /etc/pki/tls/certs" /etc/openldap/ldap.conf

sed --in-place "/^URI/ c\
URI ldaps://localhost:636" /etc/openldap/ldap.conf

sed --in-place "/^BASE/ c\
BASE ${l_basedn}" /etc/openldap/ldap.conf

sed --in-place=.${s_date} "/^binddn/ c\
binddn cn=svcSUDO,ou=serviceAccounts,dc=localdomain" /etc/sudo-ldap.conf

sed --in-place "/^bindpw/ c\
bindpw $(cat ${f_svcSUDO_passphrase})" /etc/sudo-ldap.conf

sed --in-place "/^uri/ c\
uri ldaps://localhost:636" /etc/sudo-ldap.conf


# Restart the services so the first set of ldapmodify entries can be started.

service dirsrv stop

service dirsrv-admin restart

service dirsrv start


# And make the actual working entries.

ldapmodify -v -H ldaps://localhost:636 -c -D "${l_dirmgr}" \
-w $(cat ${f_dirmgr_passphrase}) <<EOT
dn: ou=users,${l_basedn}
changeType: add
objectClass: top
objectClass: organizationalunit
ou: users

dn: ou=groups,${l_basedn}
changeType: add
objectClass: top
objectClass: organizationalunit
ou: groups

dn: cn=${l_cn},ou=users,${l_basedn}
changeType: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetorgperson
objectClass: posixAccount
objectClass: inetUser
cn: ${l_cn}
homeDirectory: ${l_homeDirectory}
uid: ${l_cn}
uidNumber: ${l_uidNumber}
gidNumber: ${l_uidNumber}
givenName: ${l_givenName}
sn: ${l_sn}
gecos: ${l_givenName} ${l_sn}
displayName: ${l_givenName} ${l_sn}
loginShell: ${l_loginShell}

dn: cn=${l_cn},ou=groups,${l_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: ${l_cn}
gidNumber: ${l_uidNumber}
member: cn=${l_cn},ou=users,${l_basedn}

dn: cn=wheel,ou=groups,${l_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: wheel
gidNumber: 10
member: cn=${l_cn},ou=users,${l_basedn}

dn: cn=users,ou=groups,${l_basedn}
changeType: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: users
gidNumber: 100
member: cn=${l_cn},ou=users,${l_basedn}

# Make our example user a Directory Administrator

dn: cn=Directory Administrators,${l_basedn}
changetype: modify
add: uniqueMember
uniqueMember: cn=${l_cn},ou=users,${l_basedn}

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
userPassword: $(cat ${f_svcAuthenticator_passphrase})
description: Service account to allow PAM/SSSD to search the LDAP database.

dn: cn=svcSudo,ou=serviceAccounts,${l_basedn}
changetype: add
objectClass: top
objectClass: person
cn: svcSudo
sn: svcSudo
userPassword: $(cat ${f_svcSUDO_passphrase})
description: Service account to allow SUDO to search the LDAP database.


#

dn: ou=SUDOers,${l_basedn}
changeType: add
description: Container for sudoer privileges.
objectClass: organizationalUnit
objectClass: top
ou: SUDOers

dn: cn=defaults,ou=SUDOers,${l_basedn}
changeType: add
cn: defaults
description: Default sudoOptions
objectClass: sudoRole
sudoOption: env_keep+=SSH_AUTH_SOCK

dn: cn=wheel,ou=SUDOers,${l_basedn}
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
-D "${l_dirmgr}" \
-w $(cat ${f_dirmgr_passphrase}) \
-b "ou=users,${l_basedn}"

ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${l_dirmgr}" \
-w $(cat ${f_dirmgr_passphrase}) \
-b "ou=Groups,${l_basedn}" \
-s sub

ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${l_dirmgr}" \
-w $(cat ${f_dirmgr_passphrase}) \
-b "ou=SUDOers,${l_basedn}"

