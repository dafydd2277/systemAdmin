#!/bin/bash
#
# getInventoryFor.sh
#
# This script will loop through all Puppet Enterprise servers listed in
# the array a_pe_servers, looking for the short hostname given as the
# first and only argument. Once that hostname is found, the script will
# pretty print the JSON inventory for that host to STDOUT.
#
#
# 2020-02-20 David Barr
# Initial script completed.
#


###
### EXPLICIT VARIABLES
###

source ./libitil.sh


# Set list of Puppet Enterprise servers.
a_pe_servers=( 
               "puppet.dev.example.com"
               "puppet.test.example.com"
               "puppet.prod.example.com"
             )

###
### FUNCTIONS
###

# Get a list of hosts and associated facts from a specified Puppet
# server.
#
# Usage: `fn_get_inventory <puppetServer> <targetHost>`
fn_get_inventory () {

  local s_server=${1:-}
  local s_target=${2:-}

  local s_target_short=$( fn_libitil_get_hostname ${s_target} )

  local s_result=$( ssh -q ${s_server} \
    "curl -v -G http://localhost:8080/pdb/query/v4/inventory?query=%5B%22%3D%22%2C%20%22facts.networking.hostname%22%2C%20%22${s_target_short}%22%20%5D" \
    2>/dev/null )


  if [ ${#s_result} -gt 2 ]
  then
    echo ${s_server}
    echo ${s_result} | python -m json.tool
  fi
}

  
###
### MAIN
###

s_host=${1:-}

if [ -z "${s_host}" ]
then
  echo "Usage: getInventoryFor.sh <hostname>"
  exit 1
fi

for s_server in ${a_pe_servers[*]}
do
  fn_get_inventory ${s_server} ${s_host}
done

