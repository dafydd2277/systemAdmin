# Setting up Kerberos 5 for Authentication.

This turned out to be absurdly easy. Just follow the instructions for [Configuring a Kerberos 5 Server][krb5server]. The few hints I have to share with you are more in the nature of customizing `/etc/krb5.conf` and `/var/kerberos/krb5kdc/kdc.conf`.
 
This is written in [Github-flavored Markdown][gmd]. For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[krb5server]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Managing_Smart_Cards/Configuring_a_Kerberos_5_Server.html
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## Prerequisites

I'm assuming you've configured [SSL][ssldir] and [LDAP][ldapdir] for Authentication/Authorization more or less as I outlined. Kerberos doesn't have to be (and shouldn't be) on the same server as your LDAP installation, but your clients will need to know both servers via `authconfig`. On the other hand, my test environment is on the same host, and I will be taking advantage of `${f_ssl_sysconfig}` and `${f_ds_sysconfig}`.

[ssldir]: https://github.com/dafydd2277/systemAdmin/tree/master/ssl
[ldapdir]: https://github.com/dafydd2277/systemAdmin/tree/master/ldap

## Set up your references

```bash
f_ssl_sysconfig=/etc/sysconfig/local-ssl
f_ds_sysconfig=/etc/sysconfig/local-ds
export f_ssl_sysconfig f_ds_sysconfig

. ${f_ssl_sysconfig}
. ${f_ds_sysconfig}


f_krb5_sysconfig=/etc/sysconfig/local-krb5
export f_krb5_sysconfig

cat <<EOT > ${f_krb5_sysconfig}
d_krb5_root=/root/.krb5
export d_krb5_root

f_masterkey_passphrase=\${d_krb5_root}/masterkey_passphrase.txt

EOT

. ${f_krb5_sysconfig}

mkdir --mode 0700 --parents ${d_krb5_root}

tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${f_masterkey_passphrase}
chown root:root ${f_masterkey_passphrase}
chmod 0400 ${f_masterkey_passphrase}

```


## Install the packages

`krb5-libs` and `krb5-workstation` are part of a standard CentOS installation. So, you may not need to explicitly install them.

```bash
yum -y install krb5-libs krb5-server krb5-workstation

```

## Edit the configuration files.

I did my editing by hand. Here are some `sed` commands that amount to the same things. The backslashes allow for using spaces to indent the start of lines, so the changes look like the original files.

```bash
s_domain_caps=$(echo ${l_domain} | tr [:lower:] [:upper:])
f_krbconf=/etc/krb5.conf
f_kdcconf=/var/kerberos/krb5kdc/kdc.conf
d_kdclog=/var/log/krb5kdc
f_kdclog=kdc.log
f_kadminlog=kadmin.log
export f_kdcconf d_kdclog f_kdclog f_kadminlog
export s_domain_caps f_krbconf

s_hostname=${hostname -s)

sed --in-place=.orig "s%^ kdc = FILE.*% kdc = FILE:${d_kdclog}/${f_kdclog}%" \
  ${f_krbconf}

sed --in-place "s%^ kadmin = FILE.*% kadmin = FILE:${d_kdclog}/${f_kadminlog}%" \
  ${f_krbconf}

sed --in-place "/^ default_realm/ c\
\ default_realm = ${s_domain_caps}" ${f_krbconf}

sed --in-place "/^ EXAMPLE\.COM/ c\
\ ${s_domain_caps} = {" ${f_krbconf}

sed --in-place "/^  kdc/ c\
\  kdc = ${s_hostname}.${l_domain}" ${f_krbconf}

sed --in-place "/^  admin_server/ c\
\  admin_server = ${s_hostname}.${l_domain}" ${f_krbconf}

sed --in-place "/^\ .example\.com/ c\
\ .${l_domain} = ${s_domain_caps}" ${f_krbconf}

sed --in-place "/^ example\.com/ c\
\ ${l_domain} = ${s_domain_caps}" ${f_krbconf}

```

([Why do I use dollar-parentheses instead of backticks in bash command expansion like `$(hostname -s)`?][faq082])

And, here are the changes for `/var/kerberos/krb5kdc/kdc.conf`. In krb5-server 1.10.3-33, the `master_key_type` is `aes256-cts` which is plenty for my purposes. You'll want to avoid weaker algorithms. [The Kerberos page on encryption types][krb5enctypes] has a full explanation. Similarly, I will modify `supported-enctypes` to leave out all the weaker ones. (As I outline [here][superuser], using the `aes` encryption family generates an error with this version of Kerberos.) Finally, add in a logging section.

```bash


sed --in-place=.orig "/^ EXAMPLE\.COM/ c\
\ ${s_domain_caps} = {" ${f_kdcconf}

sed --in-place "s/^  #master_key_type/  master_key_type/" ${f_kdcconf}

sed --in-place "/^  supported_enctypes/ c\
\    supported_enctypes = aes256-cts:special aes256-cts:normal aes128-cts:special aes128-cts:normal des3:special des3:normal" \
${f_kdcconf}

cat <<EOT >>${f_kdcconf}

[logging]
 kdc = FILE:${d_kdclog}/${f_kdclog}
 admin_server = FILE:${d_kdclog}/${f_kadminlog}

EOT

```


Then, since we're messing about with the log file settings, let's go tell `logrotate` where those files are, instead of the default location:

```bash
sed --in-place=.orig "1 s%.*%${d_kdclog}/${f_kdclog} {%" /etc/logrotate.d/krb5kdc

sed --in-place=.orig "1 s%.*%${d_kdclog}/${f_kadminlog} {%" /etc/logrotate.d/kadmind

mkdir --mode 750 --parents ${d_kdclog}
touch ${d_kdclog}/${f_kdclog} ${d_kdclog}/${f_kadminlog}
chown -R root:root ${d_kdclog}
chmod 600 ${d_kdclog}/*

```

[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[krb5enctypes]: http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_files/kdc_conf.html#encryption-types
[superuser]: http://superuser.com/questions/849798/kdb5-util-create-fails-with-an-error


## Create the KRB5 database, modify the ACL file, create the admin user, and start the service.

Use the Master Key passphrase we created earlier. Copy and paste it when the create command asks for it.

```bash
cat ${f_masterkey_passphrase}

/usr/sbin/kdb5_util create -s

sed --in-place=.orig "s/EXAMPLE\.COM/${s_domain_caps}/" /var/kerberos/krb5kdc/kadm5.acl

```

Have a password ready for your admin user. You can use the value of `${l_cn}` from your 389-DS configuration, or use root.

```bash
/usr/sbin/kadmin.local -q "addprinc ${l_cn}/admin"

```

Than, start the services.

```bash
service krb5kdc start
service kadmin start

```

Finally, add your first regular user. This might also be your admin user. Again, be prepared to provide the administrator password and a password for the new user.

```bash
kadmin -p ${l_cn}/admin -q "addprinc ${l_cn}"

```

