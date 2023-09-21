#!/bin/bash

# This is a close variation of
# https://stackoverflow.com/a/10001357

###
### STATIC VARIABLES
###

s_fromAddr='abuse@apple.com'
s_toAddr='abuse@gmail.com'


###
### DYNAMIC VARIABLES
###

s_smtpHost=${1:-localhost}
s_smtpPort=${2:-25}
s_ehlo=$( hostname --fqdn )


###
### FUNCTIONS
###

checkStatus () {
  expect=250
  if [ $# -eq 3 ] ; then
    expect="${3}"
  fi
  if [ $1 -ne $expect ] ; then
    echo "Error: ${2}"
    exit
  else
    echo "${1} ${2}"
  fi
}


###
### MAIN
###

exec 3<>/dev/tcp/${s_smtpHost}/${s_smtpPort}

read -u 3 sts line
checkStatus "${sts}" "${line}" 220

echo -e "\tHELO ${s_ehlo}"
echo "HELO ${s_ehlo}" >&3

read -u 3 sts line
checkStatus "$sts" "$line"

echo -e "\tMAIL FROM: ${s_fromAddr}"
echo "MAIL FROM: ${s_fromAddr}" >&3

read -u 3 sts line
checkStatus "$sts" "$line"

echo -e "\tRCPT TO: ${s_toAddr}"
echo "RCPT TO: ${s_toAddr}" >&3

read -u 3 sts line
checkStatus "$sts" "$line"

echo -e "\tDATA"
echo "DATA" >&3

read -u 3 sts line
checkStatus "$sts" "$line" 354

echo -e "\tFrom: ${s_fromAddr}"
echo "From: ${s_fromAddr}" >&3
echo -e "\tTo: ${s_toAddr}"
echo "To: ${s_toAddr}" >&3
echo -e "\tSubject: Test Subject at $( date )"
echo "Subject: Test Subject at $( date )" >&3
echo
echo >&3
echo -e "\tTest Body at $( date )"
echo "Test Body at $( date )" >&3
echo -e "\t."
echo "." >&3

read -u 3 sts line
checkStatus "$sts" "$line"

echo -e "\tquit"
echo "quit" >&3
read -u 3 sts line
checkStatus "$sts" "$line" 221

