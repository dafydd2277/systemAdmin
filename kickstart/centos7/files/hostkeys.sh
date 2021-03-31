#!/bin/bash
set -x
#
# hostkeys.sh
#
# Set up higher security SSH host keys.
#


###
### EXPLICIT VARIABLES
###


###
### DERIVED VARIABLES
###

export e_chmod=$( /usr/bin/which chmod )
export e_hostname=$( /usr/bin/which hostname )
export e_keygen=$( /usr/bin/which ssh-keygen )
export e_rm=$( /usr/bin/which rm )


###
### MAIN
###

${e_rm} -f /etc/ssh/*key /etc/ssh/*key.pub


${e_keygen} -vvv \
  -t dsa \
  -C "$( ${e_hostname} )" \
  -N "" \
  -f /etc/ssh/ssh_host_dsa_key

${e_keygen} -vvv \
  -t rsa \
  -b 2048 \
  -C "$( ${e_hostname} )" \
  -N "" \
  -f /etc/ssh/ssh_host_rsa_key

${e_keygen} -vvv \
  -t ecdsa \
  -b 521 \
  -C "$( ${e_hostname} )" \
  -N "" \
  -f /etc/ssh/ssh_host_ecdsa_key

${e_keygen} -vvv \
  -t ed25519 \
  -C "$( ${e_hostname} )" \
  -N "" \
  -f /etc/ssh/ssh_host_ed25519_key


# SET HOST KEY PERMISSIONS
## STIG RHEL-07-040640
${e_chmod} 0644 /etc/ssh/*key.pub

## STIG RHEL-07-040650
${e_chmod} 0600 /etc/ssh/ssh_host*key

