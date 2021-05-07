#!/usr/bin/env bash
#
# Follow along
set -x

# Moves and copies need to include dot-files.
shopt -s dotglob


###
### EXPLICIT VARIABLES
###

# The source ISO file, and its mountpoint.
df_source_iso=/tmp/CentOS-8.3.2011-x86_64-dvd1.iso
d_source_iso_mountpoint=/mnt

# The full path to your customized kickstart file.
df_kickstart=/tmp/custom-ks.cfg

# The write-out location of the modified ISO file.
df_dest_iso=/tmp/CentOS-8.3-2011-x86_64-ks.iso

# The directory used for expanding the source ISO into its component
# files.
d_build_dir=/tmp/iso

# And the device that will receive the `dd` output of the modified ISO.
d_usb_device=/dev/sdb


###
### DERIVED VARIABLES
###

# This grabs the LABEL of the source ISO, to write to the destination
# ISO.
s_source_label=$(blkid \
                --match-tag=LABEL \
                -o export \
                ${df_source_iso} \
                | grep LABEL \
                | cut -d= -f2)


###
### MAIN
###

# Can we get the LABEL from the source ISO?
if [ -z ${s_source_label} ]
then
  exit 1
fi

# Can we find the custom kickstart file?
if [ ! -e ${df_kickstart} ]
then
  exit 1
fi

# Install needed packages.
yum -y install isomd5sum syslinux pykickstart

# Create the build directory.
if [ ! -d ${d_build_dir} ]
then
  mkdir -p ${d_build_dir}
fi


# Mount the source ISO, and copy out its files to the build directory.
rm -rf ${df_dest_iso}
mount -o loop ${df_source_iso} ${d_source_iso_mountpoint}
rm -rf ${d_build_dir}/*

time cp -aRfp ${d_source_iso_mountpoint}/* ${d_build_dir}
cp -vf ${df_kickstart} ${d_build_dir}/ks.cfg


# Modify the installer boot options to include references to the
# customized kickstart files. Then, examine the diffs to make sure the
# changes are correct.
sed --in-place=.orig \
  "/append/ s%$% inst.ks=hd:LABEL=${s_source_label}%" \
  ${d_build_dir}/isolinux/isolinux.cfg
diff \
  ${d_build_dir}/isolinux/isolinux.cfg.orig \
  ${d_build_dir}/isolinux/isolinux.cfg

sed --in-place=.orig \
  "/linuxefi/ s%$% inst.ks=hd:LABEL=${s_source_label}%" \
  ${d_build_dir}/EFI/BOOT/BOOT.conf
diff \
  ${d_build_dir}/EFI/BOOT/BOOT.conf.orig \
  ${d_build_dir}/EFI/BOOT/BOOT.conf

# Bail out point for testing, before we get to the time consuming
# `mkisofs`.
#exit

cd ${d_build_dir}
time mkisofs \
  -o ${df_dest_iso} \
  -b isolinux/isolinux.bin \
  -J -R -l -v \
  -quiet \
  -c isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e images/efiboot.img \
  -no-emul-boot \
  -graft-points \
  -V "${s_source_label}" \
  -jcharset utf-8 .

# Configure the ISO to boot on UEFI systems.
isohybrid --uefi ${df_dest_iso}

# Add hashes to the customized ISO so the media checks pass.
time implantisomd5 ${df_dest_iso}

# Add another bail out point after the time consuming `mkisofs` and
# before the time consuming `dd`.
#exit

umount ${d_usb_device}1
time dd if=${df_dest_iso} of=${d_usb_device} status=progress

