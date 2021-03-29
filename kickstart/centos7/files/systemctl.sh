#!/bin/bash
set -x
#
# systemctl.sh
#
# Global/default systemctl service settings.
#

###
### EXPLICIT VARIABLES
###


###
### DERIVED VARIABLES
###

export e_systemctl=$( /usr/bin/which systemctl )


###
### MAIN
###

## STIG RHEL-07-030010
${e_systemctl} enable auditd

## STIG RHEL-07-020220
${e_systemctl} mask ctrl-alt-del.target

## STIG RHEL-07-020161
# Needed for NFS mounted home directories
${e_systemctl} enable autofs.service

## STIG RHEL-07-021230
${e_systemctl} disable kdump.service
