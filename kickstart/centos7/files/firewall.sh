#!/bin/bash
#set -x
#
# firewall-cmd.sh
#
# This sets up a minimal firewall set with the kickstart configuration.
#
# In the absense of setting all interfaces to the default zone, don't
# forget to specify their individual zones in Network Manager
#
# nmcli con modify <interface> connection.zone <zone>


${e_systemctl} enable firewalld

${e_firewallcmd} --set-default-zone=work


