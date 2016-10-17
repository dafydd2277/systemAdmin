#!/bin/bash
set -x
#
# Remove X11 from a host.
#
# (Note that java-1.7.0-openjdk and similar require xorg-x11-font-utils and
# xorg-X11-fonts-Type1. So, a host requiring openJDK will fail the STIG item
# that requires the removal of X11.)
#

if [ $(id -u) -ne 0 ]
then
  echo "Must be run as root."
fi

yum -y --disablerepo=* list xorg*
if [ $? -eq 0 ]
then
 yum -y --disablerepo=* remove \
   xorg-x11-server-common.x86_64 \
   xorg-x11-drv-ati-firmware.noarch \
   xorg-x11-font-utils.x86_64 \
   xorg-x11-fonts-Type1.noarch \
   xorg-x11-server-utils.x86_64 \
   xorg-x11-xauth.x86_64 \
   xorg-x11-xinit.x86_64 \
   xorg-x11-xkb-utils.x86_64
fi


