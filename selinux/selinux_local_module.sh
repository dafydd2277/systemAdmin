#!/bin/bash
#set -x
#
# selinux_local_module.sh </path/to/local_module.te>
#
#
# 2020-01-14 David Barr
# This time, I'm chopping out the generation of the .te file, and
# generalizing this script to take an argument of the .te file to
# be installed as a local SELinux module. If you don't have a
# specific naming convention in mind, I recommend local_<binary>.te,
# where <binary> is the name of the process or daemon that needs the
# extra SELinux privileges.
#
#
# 2019-07-02 David Barr
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
### DERIVED VARIABLES
###

df_semodule_source=${1:-}

# Where the module files are kept.
d_module_build=${d_module_build:-/root}


###
### FUNCTIONS
###

# Compile the custom module.
# Usage: fn_semodule_compile <source_dir> <module_name>
fn_semodule_compile () {
  local fn_d_source=${1:-}
  local fn_s_name=${2:-}
  
  if [ -z "${fn_d_source}" -o -z "${fn_s_name}" ]
  then
    exit 1
  fi

  chkmodule -m -mls \
    --output ${d_module_build}/${f_name}.mod \
    ${fn_d_source}/${fn_s_name}.te
}


# Get the module name from the source file name.
# Usage: fn_semodule_get_name <source_file>
fn_semodule_get_name () {
  local fn_df_source=${1:-}
  
  if [ -z "${fn_df_source}" ]
  then
    exit 1
  fi
  
  d_source=$( dirname ${fn_df_source} )
  s_semodule_name=$( basename ${fn_df_source} | cut -d. -f1 )
}


# Install the packaged local module.
# Usage: fn_semodule_install <module_name>
fn_semodule_install () {
  local fn_s_name=${1:-}
  
  if [ -z "${fn_s_name}" ]
  then
    exit 1
  fi
  
  semodule \
    --verbose \
    --install ${d_module_build}/${fn_s_name}.pp
}


# Package the compiled local module.
# Usage: fn_semodule_package <module_name>
fn_semodule_package () {
  local fn_s_name=${1:-}
  
  if [ -z "${fn_s_name}" ]
  then
    exit 1
  fi
  
  semodule_package \
    --outfile ${d_module_build}/${fn_s_name}.pp \
    --module ${d_module_build}/${fn_s_name}.mod
}

###
### MAIN
###

fn_semodule_get_name ${df_semodule_source}

fn_semodule_compile ${d_source} ${s_semodule_name}

fn_semodule_package ${s_semodule_name}

fn_semodule_install ${s_semodule_name}

# List the results. Your grep needs to capture the title of your
# module.
semodule \
  --list-modules \
  | grep local
