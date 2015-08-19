#! /bin/bash
set -x
#
# 99_resetSSL.sh
#
# This script clears your CA directory, deletes and recreates your passphrase
# files, and regenerates your keys and certificates. Needless to say, it's
# not recommended for production environments! It's purpose is for rapid
# testing of SSL framework modifications.
#
# Additionally, I wrote this to test a problem I was having with my NSS
# database in LDAP. So, you'll see some certutil and pk12util commands near
# the bottom.

f_ssl_sysconfig=/etc/sysconfig/local-ssl
export f_ssl_sysconfig
. ${f_ssl_sysconfig}

l_passlength=${1:-24}

function randomChars () {
 tr -dc A-Za-z0-9 < /dev/urandom \
   | head -c ${2:-2048} \
   | tail -c ${3:-1536} \
   | head -c ${1:-24}
}


# Using sha1sum was the original idea I got from the Internet. I don't
# remember where, now. However, sha1sum has a flaw, in that it is known to be
# a 40-character string in the character space of 0-9a-f. Dropping sha1sum
# means you can use the larger character space of A-Za-z0-9, and juggle the
# resulting string in a somewhat unpredictable way.
#
#function randomChars () {
#  tr -dc A-Za-z0-9 < /dev/urandom \
#    | head -c ${2:-2048} \
#    | sha1sum \
#    | awk '{print $1}'
#}


rm -rf ${f_host_passphrase}
randomChars ${l_passlength} > ${f_host_passphrase}

# The genpkey command following has a problem if the host passphrase doesn't
# end with a carriage return. (The other commands might, as well. I never
# bothered to test.)

echo -e "\n" >> ${f_host_passphrase}
chown root:root ${f_host_passphrase}
chmod 400 ${f_host_passphrase}

rm -rf ${f_host_key}
openssl genpkey \
-aes256 \
-algorithm RSA \
-pkeyopt rsa_keygen_bits:4096 \
-outform PEM \
-pass file:${f_host_passphrase} \
-out ${f_host_key}
chown root:root ${f_host_passphrase}
chmod 400 ${f_host_passphrase}

rm -rf ${f_host_req}
openssl req \
-new \
-key ${f_host_key} \
-passin file:${f_host_passphrase} \
-days 730 \
-subj ${host_cert_subj} \
-outform PEM \
-out ${f_host_req}

chown root:root ${f_host_req}
chmod 0400 ${f_host_req}

rm -rf ${d_ca}

mkdir -m 0700 -p \
 ${d_ca}/certs \
 ${d_ca}/crl \
 ${d_ca}/newcerts \
 ${d_ca}/requests \
 ${d_ca}/private

touch ${d_ca}/index.txt

# 014001 gets interpreted as hex, but number needs 6 digits!
# 0x36b1 is 14001 in hex...
echo 140001 > ${d_ca}/serial

rm -rf ${f_ca_passphrase}
randomChars ${l_passlength} > ${f_ca_passphrase}
chown root:root ${f_ca_passphrase}
chmod 0400 ${f_ca_passphrase}

rm ${f_ca_key}
openssl genpkey \
-aes256 \
-algorithm RSA \
-pass file:${f_ca_passphrase} \
-pkeyopt rsa_keygen_bits:4096 \
-outform PEM \
-out ${f_ca_key}
chown root:root ${f_ca_key}
chmod 0400 ${f_ca_key}

rm -rf ${f_ca_cert}
openssl req \
-new \
-x509 \
-extensions v3_ca \
-key ${f_ca_key} \
-passin file:${f_ca_passphrase} \
-days 1825 \
-subj ${ca_cert_subj} \
-out ${f_ca_cert}
chown root:root ${f_ca_cert}
chmod 0644 ${f_ca_cert}

l_hash=$(openssl x509 -noout -hash -in ${f_ca_cert})
ln -s ${f_ca_cert} /etc/pki/tls/certs/${l_hash}.0

rm -rf ${f_host_cert}
openssl ca \
-verbose \
-keyfile ${f_ca_key} \
-key $(cat ${f_ca_passphrase}) \
-cert ${f_ca_cert} \
-in ${f_host_req} \
-out ${f_host_cert}

chown root:root ${f_host_cert}
chmod 444 ${f_host_cert}

openssl verify \
-CApath /etc/pki/tls/certs/ \
-verbose \
${f_host_cert}


# Test NSSDB
# (If you just want a host certificate and CA certificate reset script,
# delete from here down.)

d_nssdb=/tmp/nssdb
l_sql_prefix=''
export d_nssdb l_sql_prefix

l_ca_name="CA certificate"
l_ds_cert_name="Domain Server certificate"
export l_ca_name l_ds_cert_name 

rm -rf ${d_nssdb}
mkdir -m 755 -p ${d_nssdb}
chown nobody:nobody ${d_nssdb}

rm -rf ${f_host_p12}
openssl pkcs12 \
  -export \
  -inkey ${f_host_key} \
  -passin pass:$(cat ${f_host_passphrase}) \
  -in ${f_host_cert} \
  -name "${l_ds_cert_name}" \
  -password file:${f_host_passphrase} \
  -out ${f_host_p12}

#openssl pkcs12 \
#  -export \
#  -inkey ${f_host_key} \
#  -passin file:${f_host_passphrase} \
#  -in ${f_host_cert} \
#  -name "${l_ds_cert_name}" \
#  -password file:${f_host_passphrase} \
#  -out ${f_host_p12}

if [ $? -ne 0 ]
then
 echo '"openssl pkcs12" failed!'
 exit 1
fi


chown root:root ${f_host_p12}
chmod 444 ${f_host_p12}

f_dsadmin_passphrase=/tmp/dsadmin_passphrase.txt
export f_dsadmin_passphrase

rm -rf ${f_dsadmin_passphrase}
randomChars ${l_passlength} > ${f_dsadmin_passphrase}
chown root:root ${f_dsadmin_passphrase}
chmod 0400 ${f_dsadmin_passphrase}


/usr/bin/certutil -A \
-d ${l_sql_prefix}${d_nssdb} \
-f ${f_dsadmin_passphrase} \
-n \"${l_ca_name}\" \
-t CT,C,C \
-a \
-i ${f_ca_cert}


pk12util -i ${f_host_p12} \
-w ${f_host_passphrase} \
-d ${l_sql_prefix}${d_nssdb} \
-k ${f_host_passphrase}

if [ $? -ne 0 ]
then
 echo '"pk12util" failed!'
 exit 1
fi


certutil -M \
-d ${l_sql_prefix}${d_nssdb} \
-f ${f_dsadmin_passphrase} \
-n "${l_ds_cert_name}" \
-t Pu,Pu,Pu \
-5 sslClient \
-5 sslServer

certutil -K -d ${l_sql_prefix}${d_nssdb} -f ${f_host_passphrase}

certutil -L -d ${l_sql_prefix}${d_nssdb} -f ${f_dsadmin_passphrase}


certutil -V \
-d ${l_sql_prefix}${d_nssdb} \
-f ${f_host_passphrase} \
-n "${l_ds_cert_name}" \
-e \
-u V



