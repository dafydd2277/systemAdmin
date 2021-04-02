#! /bin/bash
set -x
#
# David Barr, 2013-04-23
# github@dafydd.com
#
# Credit to "user783522" at stackoverflow.com.
# http://stackoverflow.com/questions/2701100/problem-changing-java-version-using-alternatives
# All I did was automate it.
 
# Do we link to /usr/java/default or /usr/java/latest? Select "default" or
# "latest" for this variable. Or, link to a specific version, eg. "1.6.0_40"

###
### USAGE TESTS
###
if [ `id -u` -ne 0 ]; then
  echo "Must run as root."
  exit 1
fi


###
### EXPLICIT VARIABLES
###

d_java_base=default
 
 
# Use vars for other paths, to shorten line lengths.
d_usr_bin=/usr/bin
d_usr_man1=/usr/share/man/man1
d_usr_java_bin=/usr/java/${d_java_base}/jre/bin
d_usr_java_man1=/usr/java/${d_java_base}/man/man1
 
 
# Install the alternative for /usr/java/default
/usr/sbin/alternatives \
--install "${d_usr_bin}/java"    "java"      "${d_usr_java_bin}/java" 1 \
--slave ${d_usr_bin}/javac       javac       ${d_usr_java_bin}/javac \
--slave ${d_usr_bin}/javadoc     javadoc     ${d_usr_java_bin}/javadoc \
--slave ${d_usr_bin}/jar         jar         ${d_usr_java_bin}/jar \
--slave ${d_usr_bin}/keytool     keytool     ${d_usr_java_bin}/keytool \
--slave ${d_usr_bin}/orbd        orbd        ${d_usr_java_bin}/orbd \
--slave ${d_usr_bin}/pack200     pack200     ${d_usr_java_bin}/pack200 \
--slave ${d_usr_bin}/rmid        rmid        ${d_usr_java_bin}/rmid \
--slave ${d_usr_bin}/rmiregistry rmiregistry ${d_usr_java_bin}/rmiregistry \
--slave ${d_usr_bin}/servertool  servertool  ${d_usr_java_bin}/servertool \
--slave ${d_usr_bin}/tnameserv   tnameserv   ${d_usr_java_bin}/tnameserv \
--slave ${d_usr_bin}/unpack200   unpack200   ${d_usr_java_bin}/unpack200 \
--slave ${d_usr_man1}/java.1.gz        java.1.gz         ${d_usr_java_man1}/java.1.gz \
--slave ${d_usr_man1}/keytool.1.gz     keytool.1.gz      ${d_usr_java_man1}/keytool.1.gz \
--slave ${d_usr_man1}/orbd.1.gz        orbd.1.gz         ${d_usr_java_man1}/orbd.1.gz \
--slave ${d_usr_man1}/pack200.1.gz     pack200.1.gz      ${d_usr_java_man1}/pack200.1.gz \
--slave ${d_usr_man1}/rmid.1.gz        rmid.1.gz         ${d_usr_java_man1}/rmid.1.gz \
--slave ${d_usr_man1}/rmiregistry.1.gz rmiregistry.1.gz  ${d_usr_java_man1}/rmiregistry.1.gz \
--slave ${d_usr_man1}/servertool.1.gz  servertool.1.gz   ${d_usr_java_man1}/servertool.1.gz \
--slave ${d_usr_man1}/tnameserv.1.gz   tnameserv.1.gz    ${d_usr_java_man1}/tnameserv.1.gz \
--slave ${d_usr_man1}/unpack200.1.gz   unpack200.1.gz    ${d_usr_java_man1}/unpack200.1.gz
 
# Run the --config and choose /usr/java/default
/usr/sbin/alternatives --config java
 
 
# gzip the man pages
gzip ${d_usr_java_man1}/*.1
 
 
# If the ${d_usr_bin}/java symlink has been abused, fix it.
if [ ! -L ${d_usr_bin}/java ] ; then
  ln -sf /etc/alternatives/java ${d_usr_bin}/java
fi
 
