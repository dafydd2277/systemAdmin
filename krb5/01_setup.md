# Setting up Kerberos 5 for Authentication.


I set up my Kerberos environment by following [ashrithr's notes][ashrithr] on [GitHub Gist][ggist]. The few hints I have to share with you are more in the nature of customizing `/etc/krb5.conf` and `/var/kerberos/krb5kdc/kdc.conf`.
 
This is written in [Github-flavored Markdown][gmd]. For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[ashrithr]: https://gist.github.com/ashrithr/4767927948eca70845db
[ggist]: https://gist.github.com/
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html


## Prerequisites

A Kerberos server requires a good common clock. So, [NTP][] is required. Additionally, I'm assuming you've configured [SSL][ssldir] and [LDAP][ldapdir] for Authentication/Authorization more or less as I outlined, and that this Kerberos server has a signed TLS certificate.  For better security, Kerberos shouldn't be on the same server as your LDAP installation.

[NTP]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/ch-Configuring_NTP_Using_the_chrony_Suite.html
[ssldir]: https://github.com/dafydd2277/systemAdmin/tree/master/ssl
[ldapdir]: https://github.com/dafydd2277/systemAdmin/tree/master/ldap


## Set up your references

```bash


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

I did my editing by hand. Here is a `patch` command that amounts to the same thing.

```bash
df_krbconf=/etc/krb5.conf
df_kdcconf=/var/kerberos/krb5kdc/kdc.conf
d_kdclog=/var/log/krb5kdc
f_kdclog=kdc.log
f_kadminlog=kadmin.log

s_domain=$(hostname -d)
s_domain_caps=$(echo ${s_domain} | tr [:lower:] [:upper:])
s_hostname=$(hostname -s)

export df_krbconf df_kdcconf d_kdclog f_kdclog f_kadminlog
export s_domain s_domain_caps s_hostname


cp ${df_krbconf} ${df_krbconf}.orig

patch <<EOKRB ${df_krbconf}
7a8
>  dns_lookup_kdc = false
12a14
>  default_realm = ${s_domain_caps}
19a22,25
> ${s_domain_caps} = {
>   kdc = ${s_hostname}.${s_domain}
>   admin_server = ${s_hostname}.${s_domain}
> }
23a30,31
>  .${s_domain} = ${s_domain_caps}
>  ${s_domain} = ${s_domain_caps}
EOKRB

```

([Why do I use dollar-parentheses instead of backticks in bash command expansion like `$(hostname -s)`?][faq082])

And, here are the changes for `/var/kerberos/krb5kdc/kdc.conf`. In krb5-server 1.10.3-33, the `master_key_type` is `aes256-cts` which is plenty for my purposes. You'll want to avoid weaker algorithms. [The Kerberos page on encryption types][krb5enctypes] has a full explanation. Similarly, I will modify `supported-enctypes` to leave out all the weaker ones. (As I outline [here][superuser], using the `aes` encryption family generates an error with this version of Kerberos.) Finally, add in a logging section.

```bash
patch <<EOKDC ${df_kdcconf}
13a14,22
> 
>  ${s_domain_caps}  = {
>   master_key_type = aes256-cts
>   acl_file = /var/kerberos/krb5kdc/kadm5.acl
>   dict_file = /usr/share/dict/words
>   admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
>   supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal
>  }
> 

```

[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[krb5enctypes]: http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_files/kdc_conf.html#encryption-types
[superuser]: http://superuser.com/questions/849798/kdb5-util-create-fails-with-an-error


## Create the KRB5 database, modify the ACL file, create the admin user, and start the service.

Use the Master Key passphrase we created earlier. Copy and paste it when the create command asks for it.

```bash
echo -e "*/admin@${s_domain_caps}\t*" >/var/kerberos/krb5kdc/kadm5.acl

cat ${f_masterkey_passphrase}

/usr/sbin/kdb5_util create -r ${s_domain_caps} -s


```

Have a password ready for your admin user. You can use the value of `${l_cn}` from your 389-DS configuration, or use `root`.

```bash
/usr/sbin/kadmin.local -q "addprinc ${l_cn}/admin"

```

Than, start the services,...

```bash
systemctl start krb5kdc.service
systemctl start kadmin.service
systemctl enable krb5kdc.service
systemctl enable kadmin.service

```

... and add a key for your server.

```bash
kadmin.local -q "addprinc -randkey ${s_hostname}/${s_domain}

```

Finally, add your first regular user. This might also be your admin user. Again, be prepared to provide the administrator password and a password for the new user.

```bash
kadmin -p root/admin -q "addprinc <user>"

```

