#!/usr/bin/env bash
set -x
shopt -s dotglob


###
### EXPLICIT VARIABLES
###

df_source_iso=/tmp/CentOS-8.3.2011-x86_64-dvd1.iso
d_source_iso_mountpoint=/mnt

df_kickstart=/tmp/custom-ks.cfg

df_dest_iso=/tmp/CentOS-8.3-2011-x86_64-ks.iso
d_build_dir=/tmp/iso
d_usb_device=/dev/sdb


###
### DERIVED VARIABLES
###

s_source_label=$(blkid \
                --match-tag=LABEL \
                -o export \
                ${df_source_iso} \
                | grep LABEL \
                | cut -d= -f2)


###
### MAIN
###

if [ -z ${s_source_label} ]
then
  exit 1
fi

if [ ! -e ${df_kickstart} ]
then
  exit 1
fi


yum -y install isomd5sum syslinux pykickstart

ksvalidator ${df_kickstart}
if [ $? != 0 ]
then
  exit 1
fi

if [ ! -d ${d_build_dir} ]
then
  mkdir -p ${d_build_dir}
fi


rm -rf ${df_dest_iso}
mount -o loop ${df_source_iso} ${d_source_iso_mountpoint}
rm -rf ${d_build_dir}/*

time cp -aRfp ${d_source_iso_mountpoint}/* ${d_build_dir}
cp -vf ${df_kickstart} ${d_build_dir}/ks.cfg


sed --in-place=.orig \
  "/append/ s%$% inst.ks=hd:LABEL=${s_source_label}%" \
  ${d_build_dir}/isolinux/isolinux.cfg
diff \
  ${d_build_dir}/isolinux/isolinux.cfg.orig \
  ${d_build_dir}/isolinux/isolinux.cfg

sed --in-place=.orig \
  "/linuxefi/ s%$% inst.ks=hd:LABEL=${s_source_label}%" \
  ${d_build_dir}/EFI/BOOT/grub.cfg
diff \
  ${d_build_dir}/EFI/BOOT/grub.cfg.orig \
  ${d_build_dir}/EFI/BOOT/grub.cfg

# Checkpoint
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
isohybrid --uefi ${df_dest_iso}
time implantisomd5 ${df_dest_iso}

# Checkpoint
#exit

umount ${d_usb_device}1
time dd if=${df_dest_iso} of=${d_usb_device} status=progress

