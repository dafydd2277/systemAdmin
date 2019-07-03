#!/bin/bash
#set -x
#
# selinux_mysql.sh
#
# This is a script I wrote for a client to add a SELinux module to 
# give MySQL permissions to write to a custom data directory.
#
# See Section 7 of
#
# https://wiki.centos.org/HowTos/SELinux
#
# for more hints and tricks on doing this. The technique for setting
# up a module file is centered around
#
# grep ${s_target} /var/log/audit/audit.log \
#   | audit2allow -m ${s_policy_name} \
#   ${df_policy_name}

###
### EXPLICIT VARIABLES
###

# The path to the base of your custom data file area.
d_data=/path/to/custom/data/directory

# Where the module files are kept.
d_module_build=/root

# Iterate the module version based on major vs. minor changes.
s_module_version="1.0"


###
### MAIN
###

# Create the module definition
cat <<EOMODULE > ${d_module_build}/mysql_local.te
module myqsl_local ${s_module_version};

require {
       type etc_runtime_t;
       type mysqld_safe_t;
       type mysqld_tmp_t;
       type user_tmpfs_t;
       type tmpfs_t;
       type mysqld_t;
       class sock_file { create unlink };
       class dir { write remove_name search getattr add_name };
       class file { write getattr read create unlink open };
}

#============= mysqld_safe_t ==============
allow mysqld_safe_t mysqld_tmp_t:dir search;

#============= mysqld_t ==============
#!!!! The source type 'mysqld_t' can write to a 'dir' of the following types:
# mysqld_log_t, mysqld_tmp_t, var_log_t, var_lib_t, var_run_t, mysqld_var_run_t,
# pcscd_var_run_t, mysqld_db_t, tmp_t, cluster_var_lib_t, cluster_var_run_t,
# root_t, cluster_conf_t, krb5_host_rcache_t, tmp_t

allow mysqld_t etc_runtime_t:dir { write remove_name add_name };
allow mysqld_t etc_runtime_t:file { write create unlink };
allow mysqld_t etc_runtime_t:sock_file unlink;
allow mysqld_t mysqld_tmp_t:sock_file { create unlink };
allow mysqld_t tmpfs_t:dir getattr;
allow mysqld_t user_tmpfs_t:dir getattr;
allow mysqld_t user_tmpfs_t:file { read getattr open };
EOMODULE


# Compile it
checkmodule -m --mls \
  --output ${d_module_build}/mysql_local.mod \
  ${d_module_build}/mysql_local.te


# Package the compiled version
semodule_package \
  --outfile ${d_module_build}/mysql_local.pp \
  --module ${d_module_build}/mysql_local.mod


# Install the module
semodule \
  --verbose \
  --install ${d_module_build}/mysql_local.pp


# List the results. Your grep needs to capture the title of your
# module.
semodule \
  --list-modules \
  | grep local


# I actually did these with explicit directories. The patterns may
# need some shell escapes to work.
semanage fcontext -a -f -d -t mysqld_db_t "${d_data}/mysql"
semanage fcontext -a -f -d -t mysqld_db_t "${d_data}/mysql(/.*)?"
semanage fcontext -a -f -- -t mysqld_db_t "${d_data}/mysql(/.*)?"
semanage fcontext -a -f -d -t mysqld_tmp_t "${d_data}/mysql/tmp"
semanage fcontext -a -f -- -t mysqld_tmp_t "${d_data}/mysql/tmp(/.*)?"

# Apply the new definitions
restorecon -Rv ${d_data}

service mysql start

# Look at /var/log/mysqld.log for additional hints/errors.

