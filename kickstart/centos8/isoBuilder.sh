#!/usr/bin/env bash
set -x
shopt -s dotglob

df_source_iso=/home/drastic/Downloads/CentOS-8.3.2011-x86_64-dvd1.iso
d_source_iso_mountpoint=/mnt

df_kickstart=/run/media/drastic/flashDrive/ks.cfg

df_dest_iso=/home/CentOS-8.3-2011-x86_64-ks.iso
d_build_dir=/home/iso
d_usb_device=/dev/sdb


rm -rf ${df_dest_iso}

mount -o loop ${df_source_iso} ${d_source_iso_mountpoint}

if [ ! -d ${d_build_dir} ]
then
  mkdir -p ${d_build_dir}
fi

rm -rf ${d_build_dir}/*
time cp -avRfp ${d_source_iso_mountpoint}/* ${d_build_dir}

cp -vf ${df_kickstart} ${d_build_dir}/ks.cfg


sed --in-place=.orig \
  "/append/ s/$/ ks=cdrom:\/ks.cfg/" \
  ${d_build_dir}/isolinux/isolinux.cfg
diff \
  ${d_build_dir}/isolinux/isolinux.cfg.orig \
  ${d_build_dir}/isolinux/isolinux.cfg

sed --in-place=.orig \
  "/linuxefi/ s/$/ inst.ks=cdrom:\/ks.cfg/" \
  ${d_build_dir}/EFI/BOOT/grub.cfg
diff \
  ${d_build_dir}/EFI/BOOT/grub.cfg.orig \
  ${d_build_dir}/EFI/BOOT/grub.cfg

cd ${d_build_dir}
time mkisofs \
  -o ${df_dest_iso} \
  -b isolinux/isolinux.bin \
  -J -R -l -v \
  -c isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e images/efiboot.img \
  -no-emul-boot \
  -graft-points \
  -V "CentOS-8-3-2011-x86_64-dvd" \
  -jcharset utf-8 .

isohybrid --uefi ${df_dest_iso}
implantisomd5 ${df_dest_iso}

umount ${d_usb_device}1
time dd if=${df_dest_iso} of=${d_usb_device} status=progress

