# Notes on Using Multipath Remote Storage

Fiber Channel and iSCSI over multipath connections are good
examples.

As a first note, [here is how you set up UDEV rules][udev] so
ASM sees the multipath `/dev/dm-*` device, instead of the
`/dev/sd*` device of an individual path.

Note that the `udevadm` commands in that page should be

```bash
$ please udevadm control --reload

$ please udevadm trigger --type=devices --action=change
```

The `--reload-rules` argument doesn't exist. (And
`alias please='sudo'` is just funny, every time I use it.)

[udev]: https://www.thegeekdiary.com/centos-rhel-7-how-to-set-udev-rules-for-asm-on-multipath-disks/
