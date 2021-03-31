# Adding a Kickstart File to an ISO

This started out as an attempt to add deliberately incomplete kickstart file to
an ISO. The idea was to have most of what you need, and then to use the visual
installer for the remainder. Unfortunately, I got caught up in a limitation of
the kickstart format. Let's start with
[Installing RHEL as an Experienced User][redhat01] for kickstart options with
the RHEL 8 family of operating systems. The limitation with using a kickstart
in an ISO is that the `repo` command doesn't accept `file://` scheme URLs. It
only works with network type schemes like `http://`, `https://` etc. This means
you cannot have the kickstart installation file scan for the packages in the
ISO file or burned flash drive.

(At some point, I might experiment with removing the package directories from
the ISO file to speed creation.)

If you insert a kickstart file into an ISO file, that kickstart file will need
to include a `network` directive to gain access to any repositories out
on your network and one or more `repo` directives for package locations. The
need to include a `network` directive implies either limiting your customized
ISO to single interface systems, or building fully customized ISOs/flash drives
for system type you need. (With the `isoBuilder.sh` script in this directory,
that's not actually hard. It's just time consuming to write out the file and
possibly burn it to a storage device.)

The good news is that I ran through these steps so many times in testing, that
I gave up and wrote the `isoBuilder.sh` script in this directory to automate
everything.

[redhat01]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user#user_kickstart-commands-for-system-configuration

## Steps

### Set your Environment

Note that you'll need enough filesystem space to handle essentially *three*
copies of your ISO file. The source ISO file, the directory for the files
copied out of the source ISO file, and the modified ISO file.

```
yum install isomd5sum syslinux pykickstart


df_source_iso=/tmp/CentOS-8.3.2011-x86_64-dvd.iso
d_source_mountpoint=/mnt

df_kickstart=/tmp/ks.cfg

df_dest_iso=/tmp/CentOS-8.3-2011-x86_64-dvd-ks.iso
d_build_dir=/temp/iso
d_usb_device=/dev/sdb

mount -o loop ${df_source_iso} ${d_source_mountpoint}
```

Use `blkid` to get the LABEL of the DVD iso. This will provide the LABEL
information for the modifications to `isolinux/isolinux.cfg` and
`EFI/BOOT/grub.cfg`, and the `-V` argument in the `mkisofs` command. If you go
looking in the files, you'll notice that the installers refer to the DVD/USB
drive by this LABEL.

```
s_source_label=$(blkid \
                --match-tag=LABEL \
                -o export \
                ${df_source_iso} \
                | grep LABEL \
                | cut -d= -f2)
```


### Create and Populate a Working Directory

```
shopt -s dotglob

mkdir -p ${d_build_dir}
cp -avRfp ${d_source_iso_mountpoint}/* ${d_build_dir}/
```

Enabling the dotglob option allows the '*' wildcard to include dot files. If a
ISO image does not include `.discinfo`, the disk's stage2 won't load, and the
customized image won't install. So, verify all dot files have been copied over.

```
ls -al
```


### Add the Kickstart File

Make sure it will run, first.

```
ksvalidator ${df_kickstart}

cp ${df_kickstart} ${d_iso_build}/ks.cfg
```


###  Modify the Boot Files

These two commands will add `inst.ks=hd:LABEL=${s_source_label}` to the end
of each `append` line in the menu section of
`${d_build_dir}/isolinux/isolinux.cfg` and the end of each `linuxefi` line in
`${d_iso_build}/EFI/BOOT/grub.cfg`. Then, the respective `diff` commands will
verify the modifications.

```
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
```


You'll have a total of four modified `append` lines, and four modified
`linuxefi` lines.


### Create the ISO

```
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
  -V "${s_source_label}" \
  -jcharset utf-8 .


isohybrid --uefi ${df_dest_iso}
implantisomd5 ${df_dest_iso}

```

Notes:
1. Don't forget the dot (`.`) at the end of the `mkisofs` command.
1. The `-boot-info-table` argument will modify one of the files in the
`isolinux/` directory. So, if you have trouble with these last steps, your
safest bet is to delete the entire copy of the generic ISO, and recopy the
files from the ISO file. To that end, having a copy of `ks.cfg` can't hurt.
1. Yes, you need two instances of `-no-emul-boot`. No, I haven't figured out
enough black magic to explain why. All of attempts to figure out `mkisofs`
boiled down to "type it exactly as it's given." I gave up on attempts to put
the arguments in any sort of lexical order. [This Red Hat blog post][blog] was
the point where I gave up and [JRTI][]'ed.
1. The `isohybrid` and `implantisomd5` commands need to be in that order so the
modifications made by `isohybrid` don't break the md5 hashes generated by
`implantisomd5`. And you need `implantisomd5` for the installer to do its disk
health checks. (And yes, that was a **headdesk** moment. D'you see this bruise
in the middle of my forehead?...)

[blog]: https://www.redhat.com/sysadmin/optimized-iso-image
[JRTI]: https://www.space.com/28445-spacex-elon-musk-drone-ships-names.html


### Burn the USB Flash Drive

```
dd if=${df_dest_iso} \
  of=${d_usb_device} \
  bs=4194304 \
  status=progress
```

(The block size is 4096 * 1024.)

Once the dd is complete, you can remove the USB flash drive and attempt to use
it to install the OS on another computer.
