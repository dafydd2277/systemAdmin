# Hardware Testing Notes.

## Mainboard and CPU.

- `cat /proc/cpuinfo` should work from the running OS or a rescue disk.
- `lm_sensors` may be installed, giving you the [sensors-detect(8)](http://linux.die.net/man/8/sensors-detect) and [sensors(1)](http://linux.die.net/man/1/sensors) commands.
- If the OS is running, look at installing [stress or stress-ng](http://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/).

## Memory

Boot your CentOS Installation DVD, `<ESC>` to the `boot:` prompt, type `memtest86`, `<ENTER>`, and follow the prompts. Once the test starts, go get a long lunch... [This site](http://fibrevillage.com/sysadmin/78-memory-test-tools-on-centos-rhel-and-other-linux) has additional options.


## Disks

- [badblocks(8)](http://linux.die.net/man/8/badblocks) - `badblocks -vn /dev/sda1` (Non-destructive) or `badblocks -vn /dev/sda1` (Destructive! This will delete data on the disk!)
- [parted(8)](http://linux.die.net/man/8/parted)
- [smartctl(8)](http://linux.die.net/man/8/smartctl) - `smartctl --all /dev/sd?`

