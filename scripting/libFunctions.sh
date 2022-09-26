# Bash Functions
#
# This file can be called by copying it into your ${HOME} as a dot
# file, and sourcing it from .bash_profile, like this.
#
# `source .libFunctions.sh`
#
# or picking it straight out of this project, like this.
#
# `source <( curl -ksS https://raw.githubusercontent.com/dafydd2277/systemAdmin/main/scripting/libFunctions.sh )`


# Create a backup of a file using a date stamp extension to the file
# name, where that extension is the Last Modified time as listed in the
# `stat` output of the file. This function is inspired by
# https://www.commandlinefu.com/commands/view/24622/create-backup-copy-of-file-adding-suffix-of-the-date-of-the-file-modification-not-todays-date
#
# Usage: `fn_archive <file>`
fn_archive () {
  local df_target=${1:-}
  
  if [ ! -z "${df_target}" ]
  then
    local s_lastmod=$( stat -c '%Y' ${df_target} )
    local s_datestamp=$( date -d @${s_lastmod} "+%Y%m%d_%H%M%S" )

    cp -pv ${df_target} ${df_target}.${s_datestamp}
  fi
}


# fn_get_disk_uuids
#
# A previous customer used Oracle ASM by assigning UUIDs to their ASM
# disks, and then using UDEV rules to assign those disks to
# /dev/disk/asm/$name, where $name was set as a UDEV matching rule for
# the discovered UUID. While this customer didn't use multipathing, I
# crafted the function to allow for that option.
#
# Usage: `fn_get_disk_uuids`
fn_git_disk_uuids () {
DEBUG=true
declare -A a_uuids
declare -A a_udev_env

  for f_dev in $( cd /dev; ls -1 sd* )
  do

    if [ $DEBUG ]
    then
      echo -n "${f_dev} - "
    fi

    s_id_serial=$( /sbin/udevadm info --query=all --name=/dev/${f_dev} \
                   | grep 'ID_SERIAL=' \
                   | cut -d"=" -f 2
                 )

     if [ $DEBUG ]
     then
       echo "${s_id_serial}"
     fi

     a_uuids[${f_dev}]=${s_id_serial}

     ls -1 /dev/disk/by-id/*${a_uuids[${f_dev}]}* | grep -q mpath
    if [ $? -eq 0 ]
    then
      a_udev_env[${f_dev}]='DM_UUID'
    else
      a_udev_env[${f_dev}]='ID_SERIAL'
    fi
  done


  for f_dev in $( cd /dev; ls -1 sd* )
  do
    echo "${f_dev} - ${a_udev_env[${f_dev}]} - ${a_uuids[${f_dev}]} - "

    #  multipath -ll | grep ${a_uuids[${f_dev}]} | egrep '^mpath.*' | cut -d' ' -f3
    multipath -ll | grep ${a_uuids[${f_dev}]}
    echo
  done

  # Then, construct the UDEV rule to match on one of these:
  #
  # ENV{ID_SERIAL}=="${a_uuids[${f_dev}]}"
  # ENV{DM_UUID}=="mpath-${a_uuids[${f_dev}]}"
  #
  # Additional useful information might come from
  #
  # for f_dm in $( ls -1 /dev/dm* )
  # do
  #   echo ${f_dm}
  #   lsblk ${f_dm}
  # done
}


# fn_git_branch
#
# I don't remember where fn_git_branch() and fn_git_color() came from.
# If you're in a git working directory, the first function will add a
# line to PS1 to display the branch you're working in, like this:
#
# PS1='\n$(fn_git_branch)\n[ \D{%F} \t ] \w\n[ \u@\e[31m\h\[\e[0m\] ] \$ '
#
# Usage: `fn_git_branch`
fn_git_branch () {
  # Get the root directory of the current git repo.
  local d_git=$( git rev-parse --show-toplevel 2>&1 )
  
  # Don't show status of home directory repo
  if [[ "${d_git}" != '/root' ]]
  then
    # Figure out the current branch, wrap in brackets and return it
    local s_branch=$( git branch --no-color 2>/dev/null \
      | sed -n '/^\*/s/^\* //p' )
    if [ -n "${s_branch}" ]; then
      echo -e "Git Branch: $( fn_git_color )${s_branch} \033[01;37m"
    fi
  else
    echo ""
  fi
}


# The second function colorizes the name of the working branch
# based on its commit and merge status. See
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# for more hints.
#
# fn_git_color
fn_git_color () {
  # Get the status of the repo and chose a color accordingly
  local s_status=`git status 2>&1`
  
  # Run through alternatives
  if [[ "${s_status}" == *'Not a git repository'* ]]
  then
    # reset if not a repository
    echo -e '\e[0m'
  elif [[ "${s_status}" != *'working directory clean'* ]]
  then
    # red if need to commit
    echo -e '\e[0;31m'
  elif [[ "${s_status}" == *'Your branch is ahead'* ]]
  then
    # yellow if need to push
    echo -e '\e[0;33m'
  else
    # else reset
    echo -e '\e[0m'
  fi
}

# fn_profile_set_history
#
# This function will set your bash history. If you have a
# centralized home directory (typically via NFS), your
# history files will be separated by hostname.
fn_profile_set_history () {
  shopt -s histappend
  shopt -s histverify
  shopt -s cmdhist
  
  readonly -p | grep -q "HISTFILE"
  if [ $? -ne 0 ]
  then
    export HISTFILE=~/.bash_history_$( hostname )
    export HISTCONTROL=ignoreboth
    export HISTIGNORE=""
    export HISTSIZE=500
    export HISTFILESIZE=10000
    export HISTTIMEFORMAT='%F %T - '
  fi
}


# Create a string of random charaacters in the set 0-9a-zA-Z
#
# Usage: `fn_randomChars [final length] [initial length > 1536] [middle cut]`
fn_randomChars () {
  local i_length=${1:-24}
  local i_start=${2:-2048}
  local i_middle_cut=${3:-1536}
  
  # Make sure the start string is at least 512 characters longer than
  # the middle cut.
  if (( $( expr ${i_middle_cut} + 512 ) -ge ${i_start} ))
  then
    i_start=$(( ${i_middle_cut} + 512 ))
  fi
  
  tr -dc A-Za-z0-9 < /dev/urandom \
    | head -c ${i_start} \
    | tail -c ${i_middle_cut} \
    | head -c ${i_length}
  echo
}


# Use a function to set the shell environment. This improves
# portability.
#
# Usage: `fn_set_environment`
fn_set_environment () {
  fn_profile_set_history

  set -o vim

  export PATH=${PATH}:/usr/lib/python/site-packages

  # This tells other commands which editor to use when editing files.
  export EDITOR="$( /usr/bin/which vim )"
  export VISUAL=${EDITOR}
  export FCEDIT=${EDITOR}

  # This allows GPG to collect passwords from SSH sessions.
  export GPG_TTY=$(tty)

  # Set a bunch of useful aliases that don't always appear.
  alias dstat='dstat -tclypmsnd --nfs3 5'
  alias egrep='egrep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias grep='grep --color=auto'
  alias l.='LC_COLLATE=C ls -d .* --color=auto'
  alias ll='LC_COLLATE=C ls -al'
  alias lld='LC_COLLATE=C ls -ald'
  alias ls='LC_COLLATE=C ls --color=auto'
  alias python3='/usr/bin/python3.8'
  alias vi='vim'
  alias view='vim -R'
  alias which='(alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot'
  alias xzegrep='xzegrep --color=auto'
  alias xzfgrep='xzfgrep --color=auto'
  alias xzgrep='xzgrep --color=auto'
  alias zegrep='zegrep --color=auto'
  alias zfgrep='zfgrep --color=auto'
  alias zgrep='zgrep --color=auto'

}


# Get current swap usage for all running processes.
#
# Usage: `fn_swap_by_process`
fn_swap_by_process () {

  local i_sum=0
  local i_overall=0

  local d_test
  for d_test in $( find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+" )
  do
    local i_pid=$( echo ${d_test} | cut -d / -f 3 )
    local s_progname=$( ps -p ${i_pid} -o comm --no-headers )
  
    local i_swap
    for i_swap in $( grep VmSwap ${d_test}/status 2>/dev/null | awk '{ print $2 }' )
    do
      let i_sum=${i_sum}+${i_swap}
    done
  
#    if (( ${i_sum} > 0 )); then
      printf "PID %6i swapped %8i KB (%s).\n" ${i_pid} ${i_sum} ${s_progname}
#    fi
  
    let i_overall=${i_overall}+${i_sum}
    i_sum=0
  done
  
  printf "Overall swap used: %8i KB.\n" ${i_overall}
}


# Run tcpdump processes on every interface. The output is to STDOUT
# with the interface name as a leading string. (This function
# requires RHEL 7 and `nmcli`.)
#
# Usage: `fn_tcpdump_all ["filter"]`
fn_tcpdump_all () {
  local s_filter=${1:-}

  # Get a space separated list of all interfaces, and skip the header
  # line.
  local s_interfaces=$( nmcli device status \
    | cut -d' ' -f1 \
    | awk 'NR>1' \
    | tr '\n' ' ' )

  # Start a `tcpdump` on each interface, and attach the interface name
  # to the start of the STDOUT.
  for s_if in ${s_interfaces}
  do
    /usr/sbin/tcpdump -l \
      -nn \
      -i ${s_if} \
      "${s_filter}"  \
      | sed 's/^/[ '"${s_if}"' ] /' 2>/dev/null &
  done
}


# Search the network for hosts with an uncertain FQDN.
#
# Usage: `fn_find_host <shortname>`
fn_find_host () {
  local h_target=${1:-}
  
  if [ -z "${h_target}" ]
  then
    return 1
  fi
  
  local a_domains=( prod.example.com \
    staging.example.com \
    test.example.com \
    buld.example.com \
    dev.example.com \
    infra.example.com \
  )
  
  for d_target in ${a_domains[*]}
  do
    host ${h_target}.${d_target} >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
      host ${h_target}.${d_target}
      return 0
    fi
  done
}

