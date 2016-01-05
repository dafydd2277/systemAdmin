# Recovering a boot filesystem.

Because I just had to do this...

## Reference

- [Reinstall a corrupted or destroyed boot filesystem](http://thanosk.net/content/reinstall-corrupted-or-destroyed-boot-partition)

## My take

The instructions in the reference assume you want to recover using boot media. However, what happens to the host you've had up for a couple years, with newer kernel revisions? So, drop the DVD entirely, and source from your internal yum repository.

```
rpm -Uvh --force http://yum.server/path/to/kernel-revision.rpm
rpm -Uvh --force http://yum.server/path/to/grub-version.rpm
rpm -Uvh --force http://yum.server/path/to/redhat-logos-version.rpm
```

Then, reinstall grub on your boot partition.

```
grub-install /dev/sda1
```

Finally, you'll have to recreate /boot/grub/grub.conf. The reference gives you a default. However, you probably have an pretty-much-equivalent host you can copy from.

```
scp <user>@<good.host>:/boot/grub/grub.conf /boot/grub/grub.conf
cd /boot/grub
ln -s grub.conf menu.lst
```

Reboot your host, and see if everything turns out all right.

