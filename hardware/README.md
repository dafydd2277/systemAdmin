# Troubleshooting Notes.

## Mainboard and CPU.

- `cat /proc/cpuinfo` should work from the running OS or a rescue disk.
- `lm_sensors` may be installed, giving you the [sensors-detect(8)](http://linux.die.net/man/8/sensors-detect) and [sensors(1)](http://linux.die.net/man/1/sensors) commands.
- If the OS is running, look at installing [stress or stress-ng](http://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/).

### System Monitoring

- [top(1)](https://linux.die.net/man/1/top)
- [dstat(1)](https://linux.die.net/man/1/dstat) - `dstat -tclypmsnd --nfs3`
    - These options require a 175 column window. If I'm concerned about a system, I'll start this in a `tmux` session, with a 15 second interval, and move on to other things until the customer alerts me of an issue.

## Memory

Boot your CentOS Installation DVD, `<ESC>` to the `boot:` prompt, type `memtest86`, `<ENTER>`, and follow the prompts. Once the test starts, go get a long lunch... [This site](http://fibrevillage.com/sysadmin/78-memory-test-tools-on-centos-rhel-and-other-linux) has additional options.


## Disks

- [badblocks(8)](http://linux.die.net/man/8/badblocks) - `badblocks -vn /dev/sda1` (Non-destructive) or `badblocks -wn /dev/sda1` (Destructive! This will delete data on the disk!)
- [parted(8)](http://linux.die.net/man/8/parted)
- [smartctl(8)](http://linux.die.net/man/8/smartctl) - `smartctl --all /dev/sd?`
- [iotop(1)](https://linux.die.net/man/1/iotop)
- [iostat(1)](https://linux.die.net/man/1/iostat) - `iostat -dkt 5`

### NFS

 - [nfsstat(8)](https://linux.die.net/man/8/nfsstat) - `nfsstat -c -Z5`
 

