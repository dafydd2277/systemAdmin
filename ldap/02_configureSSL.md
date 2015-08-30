# Configuring 389 Directory Server to use SSL

This document will walk you through the steps needed to set up SSL on [389 Directory Server 9][389ds9].

I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can create a successful RHDS installation by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[389ds9]: http://www.port389.org/
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## Dependencies

- [BASH-01_secureHistory.md][BASH-01] for good bash shell security while you're working with passwords.
- [SSL-01_setup.md][SSL-01] to set up your Certificate Signing Request for submission to a Certificate Authority. You'll need the resulting certificate and the CA's signing certificate. Optionally, you can also go through [SSL-02_setupCA.md][SSL-02] to set up your own Certificate Authority
- [ldap/01_setup.md][389DS-01] for your basic 389-DS configuration.

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md
[SSL-01]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-01_setup.md
[SSL-02]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-02_setupCA.md
[389DS-01]: https://github.com/dafydd2277/accountSecurity/blob/master/ldap/01_setup.md


## References

- http://www.openssl.org/
- [Starting the Server with SSL enabled](https://www.centos.org/docs/5/html/CDS/ag/8.0/Managing_SSL-Starting_the_Server_with_SSL_Enabled.html#Starting_the_Server_with_SSL_Enabled-Creating_a_Password_File)
- http://www.port389.org/docs/389ds/howto/howto-ssl.html
- http://www.port389.org/docs/389ds/FAQ/faq.html#converting-an-openssl-certificate-for-use-with-directory-server
- http://www.port389.org/docs/389ds/howto/howto-ssl.html#importing-an-existing-self-sign-keycert-or-3rd-party-cacert
- https://developer.mozilla.org/en-US/docs/NSS_security_tools/certutil
- https://developer.mozilla.org/en-US/docs/NSS_tools_:_pk12util


## Add to the RHDS sysconfig file.

389-DS doesn't work with regular text certificates. It has been designed to function with a [Netscape Security Services][nss] database. To simplify importing keys into an NSS database, let's add some naming variables to our local sysconfig files.

```bash
df_ds_sysconfig=/etc/sysconfig/local-ds
export df_ds_sysconfig

cat <<EOT >>${df_ds_sysconfig}

# Secure directory
d_root_ssl=/root/.ssl
export d_root_ssl

# The host passphrase.
f_host_passphrase=${d_root_ssl}/$(hostname -s)_passphrase.txt
export f_host_passphrase

# The host key.
f_host_key=${d_root_ssl}/$(hostname -s)_key.pem
export f_host_key

# The host certificate file.
f_host_cert=/etc/pki/tls/certs/$(hostname -s)_cert.pem
export f_host_cert

# PKCS12-formatted host certificate
df_host_p12=/etc/pki/tls/certs/host_cert.p12
export df_host_p12

s_ca_name="CA certificate"
s_ds_cert_name="Domain Server certificate"
s_ds_subj="CN=\${s_hostname}.\${s_domain},O=\${s_domain},L=\${s_cert_city},ST=\${s_cert_state},C=\${s_cert_country_code}"
export s_ca_name s_ds_cert_name s_ds_subj

# The location of the NSS database
d_nssdb=\${d_instance_etc}/nssdb
export d_nssdb

# The passphrase location for DS SSL startup. It must be in the instance etc
# directory.
df_ds_pinfile=\${d_nssdb}/pin.txt
export df_ds_pinfile

# NSS database format.
# Modern versions of NSS support SQLite databases. To set NSS up to use
# SQLite, set s_sql_prefix="sql:". However, 389-DS is not yet configured to use an
# SQLite database. See https://fedorahosted.org/389/ticket/47681 for more
# information.
s_sql_prefix=""
export s_sql_prefix

EOT

```

And, source this and the SSL sysconfig files.

```bash
. ${df_ds_sysconfig}
 
```


[nss]: https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS


## Create the NSS database directory and the PIN file.


```bash
mkdir --mode 755 --parents ${d_nssdb}
chown nobody:nobody ${d_nssdb}

```

When 389DS is configured for SSL, it will look in the PIN file for the password to its certificate database. Since the database is solely for 389-DS, we'll use the dsadmin password. Also, since the Directory Server is run as `nobody`, this file must be owned by `nobody`.


```bash
 echo "Internal (Software) Token:$(cat ${df_dsadmin_passphrase})" > ${df_ds_pinfile}

chown nobody:nobody ${df_ds_pinfile}
chmod 0400 ${df_ds_pinfile}

```


## Create PKCS12-format certificate files.

PKCS12 certificates incorporate keys and certificates into a single file. Since this is the only way to add keys to an NSS database, we need to create [PKCS12][] formatted versions of the host certificate.

(In writing this, I [found a bug in OpenSSL 1.0.1e][centos7854], where the `-passin` command doesn't handle the `file:` construction properly. That's why I'm using the construction given here.)

```bash
openssl pkcs12 \
-export \
-in ${df_host_cert} \
-inkey ${df_host_key} \
-passin pass:$(cat ${df_host_passphrase}) \
-name "${s_ds_cert_name}" \
-passout file:${df_dsadmin_passphrase} \
-out ${df_host_p12}

```

[PKCS12]: http://en.wikipedia.org/wiki/PKCS12
[centos7854]: http://bugs.centos.org/view.php?id=7854

## Generate the Directory Server NSS database and add certificates.

Create the database by adding the CA certificate. The `-f` switch is for a file name containing the passphrase. We'll still [space the command][BASH-01].

```bash
 /usr/bin/certutil -A \
-d ${s_sql_prefix}${d_nssdb} \
-f ${df_dsadmin_passphrase} \
-n "${s_ca_name}" \
-t CT,C,C \
-a \
-i ${df_ca_cert}

```

Then, add the host certificate, with keys. For `pk12util`, the `-w` argument is the PKCS#12 file's passphrase and the `-k` argument is NSS database's passphrase. (I think. The document calls `-k` the "slot" password, but doesn't define what a "slot" is.)

```bash
pk12util -i ${df_host_p12} \
-W $(cat ${df_dsadmin_passphrase}) \
-d ${s_sql_prefix}${d_nssdb} \
-K $(cat ${df_dsadmin_passphrase})

certutil -M \
-d ${s_sql_prefix}${d_nssdb} \
-f ${df_dsadmin_passphrase} \
-n "${s_ds_cert_name}" \
-t Pu,Pu,Pu \
-5 sslClient \
-5 sslServer

```

Validate that the keys and certificates, respectively, have been successfully entered into the database.

```bash
certutil -K -d ${s_sql_prefix}${d_nssdb} -f ${df_dsadmin_passphrase}

certutil -L -d ${s_sql_prefix}${d_nssdb} -f ${df_dsadmin_passphrase}

```

And verify the NSSDS is aware the host certificate has been signed by the CA certificate.

```bash
certutil -V \
-d ${s_sql_prefix}${d_nssdb} \
-f ${df_dsadmin_passphrase} \
-n "${s_ds_cert_name}" \
-e \
-u V

```


## Set up SSL connectivity.

Modify the RHDS `cn=config` environment to use SSL connections. Note that this [heredoc][] is over thirty lines long. Also, note that `ldapmodify` has [a space ahead of it][BASH-01].

In October of 2014, the [Poodlebleed Vulnerability][poodlebleed] in SSLv3 was announced. As SSLv3 is over 15 years old, the recommendation was to turn it off and require TLSv1, or later, connections only. So, you will also see some modifications here to turn off SSLv3, turn on TLSv1, and assign some ciphers for TLS to use. TLS reads the same `nsSSL3Ciphers` entry that SSLv3 does. That's why you see it here. The ciphers I have set are all 128 bits or larger. You'll note that I've turned off several 56-bit ciphers. For a list of all supported ciphers, you can do an ldapsearch on `cn=encryption,cn=config`. For more information, see [Section 7.9 of the Admin Guide][admin79] and [Chapter 3 of the Configuration, Command, and File Reference][config3].

(And, for an additional readability note, I'm taking advantage of the LDIF "a space in column 1 means continue the previous line" standard to list the ciphers line-by-line. You'll note that all of the cipher lines end on carriage returns, without whitespace.)


[poodlebleed]: http://www.poodlebleed.com
[admin79]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Administration_Guide/Managing_SSL-Setting_Security_Preferences.html
[config3]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Configuration_Command_and_File_Reference/Core_Server_Configuration_Reference.html#cnencryption-nsTLS1

```bash
 ldapmodify -v -x -h localhost -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: cn=config
replace: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-ssl-check-hostname
nsslapd-ssl-check-hostname: off
-
replace: nsslapd-certdir
nsslapd-certdir: ${d_nssdb}


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

EOT

```

Here are some additional configuration changes:

- Require secure binds.
- Set localhost as the only permitted insecure bind. (This doesn't create an exception. Localhost will also need secure binds. Also setting `nsslapsd-listenhost: 127.0.0.1` closes a potential loophole.)
- Set the interface identified by `${HOSTNAME}` as the only interface that will permit secure binds. This is especially handy if you're running 389-ds on a host with multiple interfaces.
- Set the Minimum Secure Socket Factor to 128 to require at least 128-bit encryption. Set this one last in any roll up `ldapmodify` you write. These changes take place immediately, and I've broken connections by setting minssf too early.
- These are also all explained in the [Configuration Reference][config311].


```bash
 ldapmodify -v -x -h localhost -c -D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) <<EOT
dn: cn=config
replace: nsslapd-require-secure-binds
nsslapd-require-secure-binds: on
-
replace: nsslapd-listenhost
nsslapd-listenhost: 127.0.0.1
-
replace: nsslapd-securelistenhost
nsslapd-securelistenhost: ${HOSTNAME}
-
replace: nsslapd-minssf
nsslapd-minssf: 128
EOT
```


Restart the services, to start SSL listening on port 636.

```bash
chown nobody:nobody ${d_nssdb}/*

service dirsrv stop

service dirsrv-admin restart

service dirsrv start

```


Verify SSL connectivity. First, we need to modify the LDAP client environment to point to our certificate directory. This is client-side. So, pointing to the NSSDB isn't what we want to do. Also, this change needs to be made on every client host. We'll also set the default URI for the LDAP host, so we don't have to enter it every time. The [ldap.conf][ldapconf] file has more information and options for saving common client-side information. (Don't forget to change the URI to reflect the actual FQDN of your LDAP host.)


```bash
sed --in-place=.$(date +%Y%m%d) \
's%^TLS_CACERTDIR.*%TLS_CACERTDIR /etc/pki/tls/certs%' /etc/openldap/ldap.conf

sed --in-place \
's%^URI.*%URI ldaps://localhost:636%' /etc/openldap/ldap.conf

sed --in-place \
"s%^BASE.*%BASE ${s_basedn}" /etc/openldap/ldap.conf

sed --in-place \
"s%^BINDDN.*%BINDDN \"${s_dirmgr}\"" /etc/openldap/ldap.conf

```

Next, let's try a query. This command assumes we're on the same host, where the Directory Manager's passphrase is available in a file. In a future file, I'll take a longer look at the client side of using LDAP for Authentication.

```bash
 ldapsearch \
-v \
-H ldaps://localhost:636 \
-D "${s_dirmgr}" \
-w $(cat ${df_dirmgr_passphrase}) \
-b "ou=groups,${s_basedn}" \
-s sub

```

Did you get a list of the groups you created? Good!

[ldapconf]: http://linux.die.net/man/5/ldap.conf
[config311]: https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/9.0/html/Configuration_Command_and_File_Reference/Core_Server_Configuration_Reference.html#cnconfig


## Configure the clients

If you added a `userPassword` attribute to your test users, we're now ready to set up a client and attempt to log in. Copy the CA certificate used to create your LDAP server's host certificate to an appropriate place on the client. Using [`${df_ca_cert}`][SSL-02] gives you a common location on all hosts. Also, execute the `sed` commands above on the client if you haven't already done so. Then, execute this [`authconfig` command][authconfig] to configure your clients authentication profile. (`authconfig -h` also gives a good summary of all available arguments to the command.)

```bash
 authconfig \
--enablecache \
--enableshadow \
--disablemd5 \
--passalgo=sha256 \
--disablenis \
--enableldap \
--enableldapauth \
--ldapserver=ldaps://localhost:636 \
--ldapbasedn=${s_basedn} \
--enableldaptls \
--enablerfc2307bis \
--ldaploadcacert=file://${df_ca_cert} \
--disablekrb5 \
--disablewinbind \
--disableipav2 \
--disablewins \
--disablehesiod \
--disablesssd \
--enablelocauthorize \
--disablepamaccess \
--disablesysnetauth \
--disablemkhomedir \
--updateall

```

One question is whether you create your user's `homeDirectory` by hand, or re-run the `authconfig` command, changing `--disablemkhomedir` to `--enablemkhomedir` to have the home directory created automatically on first login. Over the long term, your decision will rest on whether or not you plan to use `autofs`-mounted home directories.

Next, we have to teach the authentication system the bind DN and password to use to make its connections.

```bash
sed  --in-place=.$(date +%Y%m%d) "%^\[domain/default]% a\
ldap_default_bind_dn = cn=svcAuthenticator,ou=serviceAccounts,dc=localdomain" /etc/sssd/sssd.conf

sed --in-place "%^ldap_default_bind_dn% a\
ldap_default_authtok = $(cat ${df_svcAuthenticator_passphrase})" /etc/sssd/sssd.conf

```

If `sssd` is giving you trouble, you can also add the line `debug_level = 496` to the `[domain/default]` block. That will give you all useful logging to `/var/log/sssd/sssd_default.log`.

[SSL-02]: https://github.com/dafydd2277/systemAdmin/blob/master/SSL-02_setupCA.md
[authconfig]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/ch-Configuring_Authentication.html#sect-The_Authentication_Configuration_Tool-Command_Line_Version


