#!/bin/bash
#
# local_mysql_sh
#
# This script handles the fcontext changes needed for running
# MySQL under enforced SELinux.
#
# The directory path may need to be changed.

semanage fcontext -a -f -d -t mysqld_db_t "/var/mysqld/mysql"
semanage fcontext -a -f -d -t mysqld_db_t "/var/mysqld/mysql(/.*)?"
semanage fcontext -a -f -- -t mysqld_db_t "/var/mysqld/mysql(/.*)?"
semanage fcontext -a -f -d -t mysqld_tmp_t "/var/mysqld/mysql/tmp"
semanage fcontext -a -f -- -t mysqld_tmp_t "/var/mysqld/mysql/tmp(/.*)?"

# Apply the new definitions
restorecon -Rv /var/mysqld

systemctl restart mysql

# Look at /var/log/mysqld.log for additional hints/errors.
