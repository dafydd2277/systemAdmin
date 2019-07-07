# Disk Based Backups with Amanda

My collection of notes on configuration of
[AMANDA Backups][amanda], particularly involving disk devices as backup
destinations.

[amanda]: http://www.amanda.org/

## References
- [https://www.amanda.org/](https://www.amanda.org/)
- [Basic Installation][basic]
- [Backing Up Other Systems][remote]
- [Holding Disks versus Virtual Tapes][versus]
- [Setting up Holding Disks][holdingdisks]
- [Setting up Virtual Tapes][virtualtapes]


[basic]: http://wiki.zmanda.com/index.php/GSWA/Build_a_Basic_Configuration
[remote]: http://wiki.zmanda.com/index.php/GSWA/Backing_Up_Other_Systems
[versus]: https://wiki.zmanda.com/index.php/FAQ:Should_I_use_a_holdingdisk_when_the_final_destination_of_the_backup_is_a_virtual_tape%3F
[holdingdisks]: https://www.howtoforge.com/disk-backup-with-amanda-on-debian-lenny#-optional-configure-holding-disks
[virtualtapes]: https://wiki.zmanda.com/index.php/How_To:Set_Up_Virtual_Tapes


## Basic Installation

I went through the basic installation instructions with little
difficulty. I created an [encrypted filesystem][cryptofile] on a
mirrored Logical Volume Group. Then, I mounted the filesystem on
`/mnt/backup` and used that where in the instructions called for
`/amanda`. Note, though that the [holding disks page][holdingdisks]
page recommends that the holding disk not be on the same filesystem as
the `vtapes`. So, I created `/var/amanda` instead, and added a
configuration item to limit the space taking by the holding function to
2GB. (This alternative does require that we not put `/var/` in the
`disklist` file unmodified. We don't want to try to back up the holding
area. 

Additionally, I gave myself enough room to create 9 20GB "tapes," which
is enough for a 1 week rotation.

[cryptofile]: https://github.com/dafydd2277/systemAdmin/blob/master/filesystems/01_lvm_and_luks.md

```bash
mkdir -p /mnt/backup/vtapes/slot{1..9}
mkdir -p /mnt/backup/state/{curinfo,log,index}
mkdir -p /mnt/backup/log
mkdir -p /etc/amanda/localdomain
mkdir -p /var/amanda

cat <<EOAMANDA >/etc/amanda/localdomain/amanda.conf
org 	 "localdomain"

infofile "/mnt/backup/state/curinfo"
logdir   "/mnt/backup/state/log"
indexdir "/mnt/backup/state/index"
dumpuser "amandabackup"

tpchange "chg-disk:/mnt/backup/vtapes"
labelstr "localdomain-[0-9][0-9]"
autolabel "localdomain-%%" EMPTY VOLUME_ERROR
tapecycle 9
dumpcycle 1 week
amrecover_changer "changer

tapetype "DISK"
define tapetype DISK {
  length 20 gbytes
  filemark 4 kbytes
}

define dumptype gnutar-local {
  auth "local"
  compress client best
  program "GNUTAR"
}

holdingdisk hd1 {
  comment "main holding disk"
  directory "/var/amanda"
  use 2 Gb
  chunksize 1 mbyte 
}
EOAMANDA


cat <<EODISKLIST >/etc/amanda/localdomain/disklist
localhost /etc          gnutar-local
localhost /opt          gnutar-local
localhost /root         gnutar-local
localhost /usr/local    gnutar-local
localhost /var/lib      gnutar-local
localhost /var/local    gnutar-local
localhost /var/log      gnutar-local
localhost /var/named    gnutar-local
localhost /var/opt      gnutar-local
localhost /var/preserve gnutar-local
localhost /var/www      gnutar-local
EODISKLIST

```

I didn't encounter any problems until I tried backing up [other
systems](remoteHosts.md).

