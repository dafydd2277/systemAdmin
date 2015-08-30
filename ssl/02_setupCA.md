# Setting up an SSL CA in RHEL6 and clones.

You can choose to create your own Certificate Authority for signing certificates. This is cheaper and handier in internal/non-public environments.

(A product called [Dogtag Certificate System][dcs] exists to mechanize this process. It's essentially a "Certificate Authority in a box." If you're planning to become the CA for your entire Enterprise, it may be worth considering.)

This document can be run as a script by combining all of the code blocks into a single file, headed by `#! /bin/bash`. However, system account security is too important just to accept some script off of github. Therefore, I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can create a successful SSL installation by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.
 
For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[dcs]: http://pki.fedoraproject.org/
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html


## Dependencies

- These instructions take advantage of bash security features outlined in [BASH-01_secureHistory.md][BASH-01].
- These instructions assume you've already gone through [SSL-01_setup.md][SSL-01].

[BASH-01]: https://github.com/dafydd2277/accountSecurity/blob/master/BASH-01_secureHistory.md
[SSL-01]: https://github.com/dafydd2277/accountSecurity/blob/master/SSL-01_setup.md


## References

- https://www.openssl.org/
- http://spectlog.com/content/Create_Certificate_Authority_%28CA%29_instead_of_using_self-signed_Certificates
- http://www.octaldream.com/~scottm/talks/ssl/opensslca.html
- http://datacenteroverlords.com/2012/03/01/creating-your-own-ssl-certificate-authority/
- http://stackoverflow.com/questions/16659197/how-to-sign-a-clients-csr-with-openssl


## Add to the local sysconfig.

First, let's add to the local SSL sysconfig file, and re-source it.

```bash
df_ssl_sysconfig=/etc/sysconfig/local-ssl
export df_ssl_sysconfig

cat <<EOT >>${df_ssl_sysconfig}

# The private key for a internal Certificate Authority running on
# this host.
df_ca_key=\${d_root_ssl}/ca_key.pem
export df_ca_key

# The file holding the passphrase for the CA's private key.
df_ca_passphrase=\${d_root_ssl}/ca_passphrase.txt
export df_ca_passphrase

# The base directory for the internal Certificate Authority.
d_ca=/etc/pki/CA
export d_ca

# The -subj line for creating the CA certificate.
s_ca_email="abuse@gmail.com"

s_ca_cert_subj="/C=\${s_cert_country_code}/ST=\${s_cert_state}/L=\${s_cert_city}/CN=ca.\${s_domain}\/emailAddress=\${s_ca_email}/organizationName=\${s_domain}"
export s_ca_cert_subj

EOT


. ${df_ssl_sysconfig}
```

## Create directories.

Then, create the Certificate Authority directories and associated files. The serial file is the seed for assigning serial numbers to each signed certificate.

```bash
mkdir --mode 0700 --parents \
  ${d_ca}/certs \
  ${d_ca}/crl \
  ${d_ca}/newcerts \
  ${d_ca}/requests \
  ${d_ca}/private

touch ${d_ca}/index.txt
echo 014001 > ${d_ca}/serial
```

([Here is a strange][paulharvey]: `openssl` will fail if the serial number doesn't contain an even number of digits. [The speculation is][serialdigits] that this is a side effect of the 20 byte maximum specified in [RFC 3280][rfc3280].)

[paulharvey]: https://en.wikipedia.org/wiki/Paul_Harvey#On-air_persona.2C_catch_phrases.2C_trademarks.2C_and_off-air_interest
[serialdigits]: http://markmail.org/message/dj65qcuyjrecsuzx
[rfc3280]: http://www.ietf.org/rfc/rfc3280.txt


## Create the passphrase, key, and certificate for the CA.

Now, create the passphrase for your Certificate Authority key. Since the CA key and certificate will be used to sign other keys, these steps can't be skipped and still have a secure environment. Again, we'll create a 40-character string hashed from a random 2048-character string.

```bash
tr -dc A-Za-z0-9 </dev/urandom \
  | head -c 2048 \
  | sha1sum \
  | awk '{print $1}' \
  > ${df_ca_passphrase}

chown root:root ${df_ca_passphrase}
chmod 0400 ${df_ca_passphrase}
```

Then, create the key.

```bash
openssl genpkey \
-aes256 \
-algorithm RSA \
-pass file:${df_ca_passphrase} \
-pkeyopt rsa_keygen_bits:4096 \
-outform PEM \
-out ${df_ca_key}

chown root:root ${df_ca_key}
chmod 0400 ${df_ca_key}
```

And, with the key, create the CA certificate. (1825 days is 5 years.)

```bash
openssl req \
-new \
-x509 \
-extensions v3_ca \
-key ${df_ca_key} \
-passin file:${df_ca_passphrase} \
-days 1825 \
-subj ${s_ca_cert_subj} \
-out ${ddf_ca_cert}

chown root:root ${df_ca_cert}
chmod 0644 ${df_ca_cert}
```

Per the [spectlog.com][spectlog] page in the References section and the `-CApath` argument to [openssl verify][verify] man page, create a symbolic link of the CA certificate's hash to the certificate itself.

```bash
s_hash=$(openssl x509 -noout -hash -in ${df_ca_cert})
ln -s ${df_ca_cert} ${d_cert_root}/${s_hash}.0
```

[spectlog]: http://spectlog.com/content/Create_Certificate_Authority_%28CA%29_instead_of_using_self-signed_Certificates
[verify]: https://www.openssl.org/docs/apps/verify.html


## Sign the request

Finally, sign the request you created in [SSL-01_setup.md][SSL-01] with the new CA certificate. Note that we don't get to automatically load the passphrase with a `-passin` argument. Be prepared to copy and paste it by hand.

```bash
 openssl ca \
-verbose \
-keyfile ${df_ca_key} \
-key $(cat ${df_ca_passphrase}) \
-cert ${df_ca_cert} \
-in ${df_host_req} \
-out ${df_host_cert}
```


## And verify the result

This last command will verify that the new certificate has been successfully signed.

```bash
openssl verify \
-CApath ${d_cert_root} \
-verbose \
${df_host_cert}
```

And, you're done.

