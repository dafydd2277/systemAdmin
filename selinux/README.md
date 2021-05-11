# SELinux

## 2021-05-11

The RHEL 7 STIG requires that system administrators have a SELinux
context distinct from the context of regular users.
[RHEL-07-020020][stig020] requires administrators to be `sysadm_u` or
`staff_u`, as distinct from regular users set to `user_u`. I'm still
looking at this, but implementing this appears to be non-trivial. The
STIG entry includes the `semanage` commands for the user context, but
no commands for setting their associated domains to `sysadm_t` or
`staff_t`. Also, changes like

```
setsebool -P ssh_sysadm_login 1
```

may be necessary. The [ssh_selinux][manpage] just has a sentence to
explain that setting, with no larger description.

[manpage]: https://linux.die.net/man/8/ssh_selinux
[stig020]: https://rhel7stig.readthedocs.io/en/latest/medium.html#v-71971-the-operating-system-must-prevent-non-privileged-users-from-executing-privileged-functions-to-include-disabling-circumventing-or-altering-implemented-security-safeguards-countermeasures-rhel-07-020020


## 2020-01-27
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->
`selinux_local_module.sh ${te_file}` will take a `.te` file like
`local_mysql.te`, compile it, and install it into the local SELinux
configuration on a host. The script `local_mysql.sh` makes some
`fcontext` changes to the MySQL database directories.

