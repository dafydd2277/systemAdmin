# Setting up SSL in RHEL6 and clones.
 
This document can be run as a script by combining all of the code blocks into a single file, headed by `#! /bin/bash`. However, system account security is too important just to accept some script off of github. Therefore, I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can create a successful SSL installation by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.
 
For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html


## Dependencies

These instructions take advantage of bash security features outlined in [BASH-01_secureHistory.md][BASH-01].

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md


## References

- https://www.openssl.org/


## Verify OpenSSL.
 
Instead of going through a bunch of if statements and version checking, let's just throw a `yum upgrade` out there to make sure we have the most current OpenSSL package available. Remember, you need [OpenSSL 1.0.1g][openssl], or later, to avoid the [HeartBleed][] vulnerability. (Having said that, Red Hat [backported the fix to their release of 1.0.1e][bug1084875].)
 
```bash
yum upgrade openssl
```
 
[openssl]: https://www.openssl.org/
[HeartBleed]: https://en.wikipedia.org/wiki/Heartbleed
[bug1084875]: https://bugzilla.redhat.com/show_bug.cgi?id=1084875


## Create a local settings file.

SSL is a starting point for security in many areas of computer communication. Let's create a file in /etc/sysconfig to keep track of where we put our keys and certificates.


Let's start the local configuration file.

```bash
f_ssl_sysconfig=/etc/sysconfig/local-ssl
export f_ssl_sysconfig

cat <<EOT >${f_ssl_sysconfig}
# These are local file and directory locations for SSL elements.

# Create a short hostname variable.
s_hostname_s=$(hostname -s)

# Secure directory
d_root_ssl=/root/.ssl
d_cert_root=/etc/pki/tls/certs
export d_root_ssl d_cert_root

# Passphrase to encrypt the host key.
df_host_passphrase=\${d_root_ssl}/host_passphrase.txt
export df_host_passphrase

# The private key for this host's certificates and requests.
df_host_key=\${d_root_ssl}/${s_hostname_s}_key.pem
export df_host_key

# The host certificate request.
df_host_req=\${d_cert_root}/${s_hostname_s}_req.pem
export df_host_req

# The host certificate file.
df_host_cert=\${d_cert_root}/${s_hostname_s}_cert.pem
export df_host_cert

EOT
```


Now, let's add another set of lines to the file. This is the information that will be used to identify your host certificate to the world. If you're developing your SSL skills and techniques, entering this information interactively every time you generate a Certificate Signing Request is a pain. So, let's set it in a variable.

```bash
cat <<EOT >>${f_ssl_sysconfig}

# X.509 information for the host certificate.
l_cert_country_code="US"
l_cert_state="WA"
l_cert_city="Seattle"
l_domain="example.com"
export l_cert_country_code l_cert_state l_cert_city l_domain

l_host_cert_subj="/C=\${l_cert_country_code}/ST=\${l_cert_state}/L=\${l_cert_city}/CN=\$(hostname -s).\${l_domain}/organizationName=\${l_domain}"
export l_host_cert_subj

EOT
```

([Why do I use dollar-parentheses instead of backticks in bash command expansion like `$(hostname -s)`?][faq082] Also, in this particular case, `$(hostname)` might return and FQDN or might return a simple hostname. So, using `$(hostname -s).${l_domain} will get me a good answer in any case.)

The backslashes in front of the dollar signs, here, mean the variable strings are going to be copied into the file without any attempts at substitution. The variables don't actually exist, yet! They won't until we actually source the sysconfig file. Let's do that next.

```bash
. ${f_ssl_sysconfig}

mkdir -m 700 -p ${d_root_ssl}
chown root:root ${d_root_ssl}
```

## Create a host key and certificate request.

Next, create the host key. Some references recommend encrypting the key with a passphrase. However, generally, the existance of the certificate is sufficient to authenticate the host. That is, you only need a certificate and a matching hostname to authenticate. The existance or lack of a passphrase for the key won't change that. So, a passphrase isn't strictly necessary. Here's the key creation command without a passphrase.

```bash
openssl genpkey \
-algorithm RSA \
-pkeyopt rsa_keygen_bits:4096 \
-outform PEM \
-out ${f_host_key}

chown root:root ${f_host_key}
chmod 0400 ${f_host_key}
```

([`genpkey` has superceded `genrsa`.][openssl_man])

If you choose to encrypt your key with a passphrase, create a passphrase file to keep it in, and add a line to the openssl command. In this example, we take the additional step of creating a random 40-character SHA1 hash based on a 2048 character string extracted from `/dev/random`. Since we'll (almost) never enter the passphrase by hand, we don't need to worry about something memorable. 

**IMPORTANT:** If you are planning a Red Hat Directory Server on this host, the NSSDB will expect the host certificate to have a passphrase associated with it. Use this option for that scenario.

```bash
tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${f_host_passphrase}

chown root:root ${f_host_passphrase}
chmod 0400 ${f_host_passphrase}

openssl genpkey \
-aes256 \
-algorithm RSA \
-pass file:${f_host_passphrase} \
-pkeyopt rsa_keygen_bits:4096 \
-outform PEM \
-out ${f_host_key}

chown root:root ${f_host_key}
chmod 0400 ${f_host_key}
```

Now, let's generate the request. Here's the command for an unencrypted private key.

```bash
openssl req \
-new \
-key ${f_host_key} \
-days 730 \
-subj ${l_host_cert_subj} \
-outform PEM \
-out ${f_host_req}

chown root:root ${f_host_req}
chmod 0400 ${f_host_req}
```

And, here's the command when the private key has been encrypted.

```bash
openssl req \
-new \
-key ${f_host_key} \
-passin file:${f_host_passphrase} \
-days 730 \
-subj ${l_host_cert_subj} \
-outform PEM \
-out ${f_host_req}

chown root:root ${f_host_req}
chmod 0400 ${f_host_req}
```


Now, you can send off your Certificate Signing Request to an established and well-known Certificate Authority, pay the fee, and get your signed certificate back. For public facing hosts, this is best. On the other hand, you can also create your own Certificate Authority for internal use.

 
[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[openssl_man]: https://www.openssl.org/docs/apps/openssl.html

