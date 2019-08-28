# Setting up SSL in RHEL6 and clones.
 
Please review all steps, and adjust to suit your environment.
 
For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html


## Dependencies

These instructions take advantage of bash security features outlined in [BASH-01_secureHistory.md][BASH-01].

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md


## References

- https://www.openssl.org/


## Verify OpenSSL.
 
Instead of going through a bunch of if statements and version checking,
let's just throw a `yum upgrade` out there to make sure we have the
most current OpenSSL package available. Remember, you need
[OpenSSL 1.0.1g][openssl], or later, to avoid the [HeartBleed][]
vulnerability. (Having said that, Red Hat
[backported the fix to their release of 1.0.1e][bug1084875].)
 
```bash
yum upgrade openssl
```
 
[openssl]: https://www.openssl.org/
[HeartBleed]: https://en.wikipedia.org/wiki/Heartbleed
[bug1084875]: https://bugzilla.redhat.com/show_bug.cgi?id=1084875


## Create a local settings file.

SSL is a starting point for security in many areas of computer
communication. Let's create a file in /etc/sysconfig to keep track of
where we put our keys and certificates.


Let's start the local configuration file.

```bash
df_ssl_sysconfig=/etc/sysconfig/local-ssl
export df_ssl_sysconfig

cat <<"EOSYSCONFIG" >${df_ssl_sysconfig}
# These are local file and directory locations for SSL elements.

# Create a short hostname variable.
s_hostname_s=$ (hostname -s )
s_domain=$( hostname -d )
export s_hostname_s s_domain


# Secure directory
d_root_ssl=/root/.ssl
d_cert_root=/etc/pki/tls
export d_root_ssl d_cert_root

# Passphrase to encrypt the host key.
df_host_passphrase=${d_root_ssl}/host_passphrase.txt
export df_host_passphrase

# The private key for this host's certificates and requests.
df_host_key=${d_cert_root}/private/${s_hostname_s}.${s_domain}.key
export df_host_key

# The host certificate request.
df_host_req=${d_cert_root}/${s_hostname_s}.${s_domain}.req
export df_host_req

# The host certificate file.
df_host_cert=${d_cert_root}/certs/${s_hostname_s}.${s_domain}.pem
export df_host_cert

# The CA certificate, once we get it.
df_ca_cert=${d_cert_root}/certs/ca_cert.pem
export df_ca_cert

EOSYSCONFIG

```


Now, let's add another set of lines to the file. This is the
information that will be used to identify your host certificate to the
world. If you're developing your SSL skills and techniques, entering
this information interactively every time you generate a Certificate
Signing Request is a pain. So, let's set it in a variable.

```bash
cat <<"EOSYSCONFIG" >>${df_ssl_sysconfig}

# X.509 information for the host certificate.
i_expire_days=720
s_cert_country_code="US"
s_cert_state="WA"
s_cert_city="Seattle"
s_cert_org="Private"
s_cert_org_unit="Data Center"
s_cert_org_email="abuse@google.com"

export i_expire_days
export s_cert_country_code s_cert_state s_cert_city
export s_cert_org s_cert_org_unit s_cert_org_email 

EOSYSCONFIG

```


- [Why do I use dollar-parentheses instead of backticks in bash
command expansion like `$(hostname -s)`?][faq082]
    - Also, in this particular case, `$(hostname)` might return the
FQDN or might return a simple hostname. So, using
`$(hostname -s).${s_domain} will get me a good answer in any case.
- And, see [Example 19-6 of the bash guide at TLDP][bash196] for why
I'm quoting my heredoc limit string.


[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[bash196]: http://tldp.org/LDP/abs/html/here-docs.html

```bash
source ${df_ssl_sysconfig}

mkdir -m 700 -p ${d_root_ssl}
chown root:root ${d_root_ssl}
```

## Create a host key and certificate request.

If you choose to encrypt your key with a passphrase, create a
passphrase file to keep it in, and add a line to the openssl command.

**IMPORTANT:** If you are planning a Red Hat Directory Server on this
host, the NSSDB will expect the host certificate to have a passphrase
associated with it. Use this option for that scenario.

```bash
source <(curl -sS https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/scripting/functions)

fn_randomChars 38 > ${df_host_passphrase}

chown root:root ${df_host_passphrase}
chmod 0400 ${df_host_passphrase}

```


The key request is derived from [this blog entry][altnames]. Obviously,
you'll want to change entries for the `config` section. Note that
current versions of Chrome don't consider `CommonName` (`CN`) a
sufficient identifier, and that the `[ req_ext ]` and `[ alt_names ]`
config sections are now required in an x509 certificate.

Also, note that the `[alt_names]` entry below includes options you
frequently won't need. Include any CNAME aliases that will point to
this system. Rarely, you'll need to request a wildcard alias
( `*.${s_hostname_s}.${s_domain}` ) to allow for multiple granular URIs
that will come to this host. Remember to keep the `DNS.1`,
`DNS.2`, etc., in order, without skipping ordinals. For a deep dive
into how to build a certificate configuration file, see the
[x509v3_config man page][x509v3_config].

[altnames]: https://www.endpoint.com/blog/2014/10/30/openssl-csr-with-alternative-names-one
[x509v3_config]: http://openssl.cs.utah.edu/docs/apps/x509v3_config.html

Now, let's generate the request. Here's the command for an unencrypted
private key.

```bash
openssl req -new \
  -x50 \
  -days ${i-expire_days} \
  -out ${df_host_req} \
  -newkey rsa \
  -keyout ${df_host_key} \
  -config <(
cat <<-EOF
[req]
default_bits = 2048
prompt = no
default_md = sha1
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=${s_cert_country_code}
ST=${s_cert_state}
L=${s_cert_city}
O=${s_cert_org}
OU=${s_cert_org_unit}
emailAddress=${s_cert_org_email}
CN=${s_hostname_s}.${s_domain}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${s_hostname_s}.${s_domain}
DNS.2 = <CNAME>.${s_domain}
DNS.3 = *.${s_hostname_s}.${s_domain}

EOF

)

chown root:root ${df_host_req}
chmod 0400 ${df_host_req}

```


And, here's the command when the private key has to be encrypted.

```bash
openssl req -new \
  -x509 \
  -days ${i_expire_days} \
  -out ${df_host_req} \
  -newkey rsa \
  -passout file:${df_host_passphrase} \
  -keyout ${df_host_key} \
  -config <(
cat <<-EOF
[req]
default_bits = 2048
prompt = no
default_md = sha1
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=${s_cert_country_code}
ST=${s_cert_state}
L=${s_cert_city}
O=${s_cert_org}
OU=${s_cert_org_unit}
emailAddress=${s_cert_org_email}
CN=${s_hostname_s}.${s_domain}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${s_hostname_s}.${s_domain}
DNS.2 = <CNAME>.${s_domain}
DNS.3 = *.${s_hostname_s}.${s_domain}

EOF

)

chown root:root ${df_host_req} ${df_host_key}
chmod 0400 ${df_host_req} ${df_host_key}

```


Now, you can send off your Certificate Signing Request to an
someone like [SSL For Free][sslforfree] and get your signed certificate
back. For public facing hosts, this is best. On the other hand, you can
also create your own Certificate Authority for internal use.

[sslforfree]: https://www.sslforfree.com/

