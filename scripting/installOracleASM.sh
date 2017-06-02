#! /bin/bash
#set -x
#
# installOracleASM.sh
#
# In RHEL-family Operating Systems, Oracle ASM disks can be identified
# using UDEV rules. This script adopts the convention that a new,
# unformatted disk will have a single primary partition set on
# partition 4. That allows administrators to immediately identify disk
# devices that have been set aside for Oracle ASM disks. Additionally,
# this will identify the disks by UUID, and create rules in the file
# ${df_udev_rules} to create block device files in ${d_device_files}.
#
# If your Oracle host is virtualized on a VMware ESXi platform, you
# will need to edit the VM's properties. In the "Options" tab,
# select "Advanced/General." There, select "Configuration Parameters."
# Click on "Add Row." The name of the new parameter will be
# "disk.EnableUUID", without the quotes, and value of the parameter
# will be "true", again without the quotes.
#
# Search for "CHANGEME" to find variables that must be set before use.
#


###
### USAGE VALIDATIONS
###

if [ "$(id -u)" -ne 0 ]
then
 echo "Usage: $0"
 echo "Must be run as root."
 exit 1
fi


###
### EXPLICIT VARIABLES
###

# In the UDEV rule, the "/dev/" is assumed. So, this variable will
# result in the ASM device file being placed in
# /dev/${d_device_files}/<disk name>
d_device_files="disk/asm"

# The location of the UDEV rules file.
df_udev_rules="/etc/udev/rules.d/99-oracle-asmdevices.rules"

# Owner, group, and permissions of the resulting ASM devices files.
s_owner=grid
s_group=dba
s_perms=0660

# The location of globalvars.sh, to pick up global script variables.
# CHANGME
h_script_source=host.sub.dom.ain
d_script_path=scripts/oracle

# Disk arrays with non-numeric indexes must be defined in advance.
declare -Ax a_disk_functions
declare -ax a_disk_indexes_sorted
declare -Ax a_disk_sizes
declare -Ax a_disk_uuids


###
### DERIVED VARIABLES
###

# COMMANDS
e_fdisk=$( /usr/bin/which fdisk )
e_pvscan=$( /usr/bin/which pvscan )


# GET THE GLOBAL VARIABLES
# Many variables below this point are set in this script.
source <( $( /usr/bin/which curl ) -s http://${h_script_source}/${d_script_path}/globalvars.sh )


# CREATE A UDEV RULE TEMPLATE
case ${i_major_version} in
 '5')
   # UNTESTED. FOR HISTORICAL PURPOSES ONLY
   e_scsi_id=$( /usr/bin/which scsi_id )
   s_scsi_args='-g -u -s /block'
   s_udev_line="KERNEL==\"sd*4\", BUS==\"scsi\", PROGRAM==\"/lib/udev/scsi_id -g -u -s /block/\$parent\", RESULT==\"SED_UUID\", NAME=\"${d_device_files}/SED_NAME\", OWNER=\"${s_owner}\", GROUP=\"${s_group}\", MODE=\"${s_perms}\""
   ;;
 '6')
   e_scsi_id=$( /usr/bin/which scsi_id )
   s_scsi_args='-g -u -d /dev'
   s_udev_line="KERNEL==\"sd*4\", BUS==\"scsi\", PROGRAM==\"/lib/udev/scsi_id -g -u -d /dev/\$parent\", RESULT==\"SED_UUID\", NAME=\"${d_device_files}/SED_NAME\", OWNER=\"${s_owner}\", GROUP=\"${s_group}\", MODE=\"${s_perms}\""
   ;;
 '7')
   # http://houseofbrick.com/udev-rules/
   # https://unix.stackexchange.com/questions/119593/is-there-a-way-to-change-device-names-in-dev-directory
   # Also `lsscsi -i`
   e_scsi_id=/usr/lib/udev/scsi_id
   s_scsi_args='-g -u -d /dev'
   s_udev_line="KERNEL==\"sd*4\", SUBSYSTEM==\"block\", PROGRAM==\"/usr/lib/udev/scsi_id -g -u -d /dev/\$parent\", RESULT==\"SED_UUID\", SYMLINK+=\"${d_device_files}/SED_NAME\", OWNER=\"${s_owner}\", GROUP=\"${s_group}\", MODE=\"${s_perms}\""
   ;;
esac


###
### FUNCTIONS
###

# IDENTIFY AND ASSIGN ASM DISKS
fn_asm_assign_disk () {
  PS3="Please select the disk to assign (ctrl-d to exit): "
 
  ${e_echo}
  select s_test_disk in "${a_disk_indexes_sorted[@]}"
  do
    case ${REPLY} in
      * )
        ${e_echo} -e "You selected ${s_test_disk}."
        read -p "Is this correct (y/n)? " s_response
        ${e_echo}
        # (This only works in bash 3+.)
        if [[ "${s_response}" =~ ^(y|Y|yes|Yes|YES)$ ]]
        then
          if [ -z "${a_disk_functions[${s_test_disk}]}" ]
          then
            fn_asm_set_partition ${s_test_disk}
 
            read -p "ASM name for this disk (eg. DATA03, RECO01): " \
              s_asm_name
            fn_asm_write_rule \
              ${a_disk_uuids[${s_test_disk}]} \
              ${s_asm_name}
 
          else
            echo "That disk is already assigned."
            echo "Please select again."
          fi
        fi
        ;;
    esac
  done
}


# SCAN KEYS OF ${a_disk_uuids[@]} FOR DISK FUNCTION
# (WHAT IS THE DISK USED FOR?)
fn_asm_get_functions () {
  for s_disk_name in ${a_disk_indexes_sorted[@]}
  do
    if [ -e "${df_udev_rules}" ]
    then
      # ISOLATE THE NAME ELEMENT OF THE RULE, IF IT EXISTS.
      # THE CUT SEPARATOR IS A COMMA.
      s_function=$( ${e_grep} ${a_disk_uuids[${s_disk_name}]} ${df_udev_rules} \
        | ${e_cut} -d, -f 5 )
    fi
 
    if [ ! -z "${s_function}" ]
    then
      # ISOLATE THE NAME ITSELF
      s_function=$( ${e_echo} ${s_function} | ${e_awk} -F/ '{print $NF}' )
      # AND DROP THE TRAILING DOUBLE QUOTE
      # ${#s_function} IS THE NUMBER OF CHARACTERS IN THE STRING
      s_function=${s_function:0:${#s_function}-1}
    else
      # GET THE LVM VOLUME GROUP
      s_function=$( ${e_pvscan} \
        | ${e_grep} ${s_disk_name} \
        | ${e_awk} '{print $4}' )
    fi
 
    if [ -z "${s_function}" ]
    then
      a_disk_functions[${s_disk_name}]=""
    else
      a_disk_functions[${s_disk_name}]="${s_function}"
    fi
 
    unset s_function
  done
}


# SCAN KEYS OF ${a_disk_uuids[@]} FOR DISK SIZES
fn_asm_get_sizes () {

  # BASH ASSOCIATIVE ARRAYS WILL LIST KEYS WITH THE BANG CHARACTER:
  # ${!name[@]}. DROP THE BANG TO LIST ALL VALUES: ${name[@]}.
  for s_disk_name in ${a_disk_indexes_sorted[@]}
  do
    i_disk_size=$(cat /sys/block/${s_disk_name}/size 2>/dev/null)
    i_disk_size=$((i_disk_size / 1024 / 1024 / 2))
    a_disk_sizes[${s_disk_name}]="${i_disk_size}"
    unset i_disk_size
  done
 }
 
 
 # SCAN ALL DISK LETTERS FOR DISKS AND UUIDS
 fn_asm_get_uuids () {
  for s_disk_letter in {a..z}
  do
    s_disk_uuid=$( ${e_scsi_id} ${s_scsi_args}/sd${s_disk_letter} )
 
    if [ ! -z "${s_disk_uuid}" ]
    then
      # PUSH THE DRIVE LETTER AND THE FOUND UUID ONTO THE ARRAY
      a_disk_uuids[sd${s_disk_letter}]="${s_disk_uuid}"
    fi
 
    unset s_disk_uuid
 
  done
}


# LIST ALL FOUND DISKS
fn_asm_list_disks () {
  ${e_printf} "\n%*s %*s %*s %*s\n" \
    -6 'Device' \
    -34 'UUID' \
    -3 'Gb' \
    -11 'Purpose'
  for s_disk_name in ${a_disk_indexes_sorted[@]}
  do
    ${e_printf} "%*s %*s %*s %*s\n" \
      -6 ${s_disk_name} \
      -34 ${a_disk_uuids[${s_disk_name}]} \
      2 ${a_disk_sizes[${s_disk_name}]} \
      -12 ${a_disk_functions[${s_disk_name}]}
  done
}


# SET PARTIITON 4 ON AN UNPARTITIONED DISK
fn_asm_set_partition () {
  # WHICH DISK?
  local s_disk=${1}
  # HOW MANY PARTITIONS?
  local i_num_parts=$( ${e_fdisk} -l /dev/${s_disk} \
    | ${e_grep} -v bytes \
    | ${e_grep} ${s_disk} \
    | ${e_grep} -v ${s_disk}4 \
    | ${e_wc} -l )
  # ALREADY PARTITION 4?
  local s_part_4=$( ${e_fdisk} -l /dev/${s_disk} \
    | ${e_grep} ${s_disk}4 \
    | ${e_awk} '{print $1}' )
 
  if [ "${i_num_parts}" -gt 0 ]
  then
    # WARN THAT THIS DISK IS ALREADY IN USE
    echo "WARNING: Disk ${s_disk} already has ${i_num_parts} other partitions on it."
  elif [ -z "${s_part_4}" ]
  then
    # CREATE PARTITION 4
    ( ${e_echo} n; \
      ${e_echo} p; \
      ${e_echo} 4; \
      ${e_echo}; ${e_echo}; ${e_echo}; \
      ${e_echo} w; ) \
        | ${e_fdisk} /dev/${s_disk}
    ${e_echo} "INFO: /dev/${s_disk}4 created."
  else
    ${e_echo} "WARNING: Disk ${s_disk} already has partition 4 on it."
  fi
 
  unset s_disk i_num_parts s_part_4
}


# CREATE A SORTED KEY LIST OF DISK NAMES
# SET DISK TYPE (LVM, ASM, ETC) AS VALUE
# http://stackoverflow.com/a/12681596
fn_asm_sort_keys () {
  s_old_ifs=$IFS
  IFS=$'\n'
  a_disk_indexes_sorted=( $( ${e_printf} '%s\n' "${!a_disk_uuids[@]}" \
    | ${e_sed} -r -e 's/^ *//' -e '/^$/d' | ${e_sort} ) )
  IFS=${s_old_ifs}
}


# WRITE A RULE INTO THE ASM RULES FILE
fn_asm_write_rule () {
  local s_uuid=${1}
  local s_asm_name=${2}
 
  if [ -e ${df_udev_rules} ]
  then
    ${e_cp} ${df_udev_rules} \
      ${df_udev_rules}.$( ${e_date} +%Y%m%d_%H%M%S )
  fi
 
  ${e_echo} ${s_udev_line} >> ${df_udev_rules}
  ${e_sed} --in-place \
    "s/SED_UUID/${s_uuid}/" \
    ${df_udev_rules}
  ${e_sed} --in-place \
    "s/SED_NAME/${s_asm_name}/" \
    ${df_udev_rules}
 
  ${e_echo} "UUID ${s_uuid}"
  ${e_echo} "set to ${s_asm_name}"
  ${e_echo} "in ${df_udev_rules}."
 
  unset s_uuid s_asm_name
 
  fn_asm_get_functions
  fn_asm_list_disks
}


###
### MAIN
###

fn_asm_get_uuids
fn_asm_sort_keys

fn_asm_get_sizes
fn_asm_get_functions

fn_asm_list_disks

fn_asm_assign_disk

set +x


