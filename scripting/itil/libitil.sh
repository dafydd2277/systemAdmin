###
### EXPLICIT VARIABLES
###

# If not already set as an environment variable, set the ITIL database
# name.
df_itildb=${df_itildb:-/usr/local/lib/itil/itil.sqlite}


###
### DERIVED VARIABLES
###

# Parameterize the sqlite3 executable, with its full path.
e_sqlite3=$( /usr/bin/which sqlite3 )


###
### FUNCTIONS
###

# Add a set of hosts from a text file of FQDNs.
#
# This function will take a file of FQDNs, one per line, split those
# FQDNs into hostname and domainname, and insert those values into the
# hosts table. If an FQDN already exists in the table, it will be
# skipped with an error.
#
# Usage: `fn_libitil_add_hosts <file>`
fn_libitil_add_hosts () {
  local df_target=${1:-}

  if [ -z "${df_target}" ]
  then
    return 1
  fi

  for s_line in $( cat ${df_target} )
  do

    # Skip commented or blank lines.
    if [ "${s_line:0:1}" == '#' ]
      or [ -z "${s_line}" ]
    then
      continue
    fi

    s_hostname=$( fn_libitil_get_hostname "${s_line}" )
    s_domainname=$( fn_libitil_get_domainname "${s_line}" )

    echo ${s_hostname}.${s_domainname}

    echo 'INSERT into hosts
      (hostname, domainname)
      VALUES 
      ( "'"${s_hostname}"'", "'"${s_domainname}"'" );' \
    | ${e_sqlite3} ${df_itildb}

  done
}


# Create the initial ITIL database tables.
#
# This collects the set of table creation functions, to create the
# database all in one go. This allows customization of the individual
# table creation functions, and allows additional table creation
# functions to be added and executed without risking the entire
# database.
#
# The hosts table needs to be created first, because many other tables
# use hostname and domainname as foreign keys.
#
# Usage: `fn_libutil_create_database`
fn_libitil_create_database () {
  # The hosts table needs to come first.
  fn_libitil_create_table_hosts
  fn_libitil_create_table_notes
  fn_libitil_create_table_systems

  # The applications table needs to come before application_owners
  # table.
  fn_libitil_create_table_applications
  fn_libitil_create_table_application_owners

  # Interfaces needs to come before addresses.
  fn_libitil_create_table_interfaces
  fn_libitil_create_table_addresses
}


# Create the network address table.
#
# The database needs separate tables for those host/OS resources that
# might occur many times on a given host, like ip addresses, LVM
# configurations, or filesystems. Creating tables for these resources
# should use a primary key and foreign key scheme similar to the one
# shown here.
#
# "address_name" is typically derived from the hostname, eg
# "prod1_mgmt."
#
# Usage: `fn_libitil_create_table_addresses`
fn_libitil_create_table_addresses () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS interfaces (
      hostname varchar(20)
        REFERENCES hosts (hostname)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      domainname varchar(40)
        REFERENCES hosts (domainname)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      address_name varchar(20),
      address_type varchar(20),
      address_value varchar(40),
      address_mask varchar(40),
      gateway varchar(40),
      interface_name varchar(10)
        REFERENCES interfaces (interface_name)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      last_updated text DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY
        (hostname, domainname,
        address_name)
        ON CONFLICT FAIL
    );'
}


# Create the applications table.
#
# The applications table is the combination of application names, and
# the hosts & domains they're running on.
#
# Usage: `fn_libitil_create_table_applications`
fn_libitil_create_table_applications () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS applications (
      hostname varchar(20)
        REFERENCES hosts (hostname)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      domainname varchar(40)
        REFERENCES hosts (domainname)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      application_name varchar(40),
      application_version varchar(12),
      application_description varchar(128),
      last_updated text DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY
        (hostname, domainname,
        application_name)
        ON CONFLICT FAIL
    );'
}


# Create the application owners table.
#
# The application owners table collects any number of owners for a
# given application. The value of primary_owner can either be 0 (false)
# or 1 (true).
#
# Usage: `fn_libitil_create_table_application_owners`
fn_libitil_create_table_application_owners () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS application_owners (
      application_name varchar(40)
        REFERENCES applications (application_name)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      owner varchar(60),
      primary_owner tinyint DEFAULT 0,
      department varchar(100),
      last_updated text DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY(application_name, owner)
        ON CONFLICT FAIL
    );'
}


# Create the hosts table.
#
# The hosts table is FQDN, OS, "what it's for," and "who to ask about
# it." Details are kept in other tables, referring back to here. Note
# that every column aside from hostname and domainname are Puppet
# facter entries. Those values could be picked out of the PuppetDB
# using a read-only API to avoid data duplication.
#
# Usage: `fn_libutil_create_table_hosts`
fn_libitil_create_table_hosts () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS hosts (
      hostname varchar(20),
      domainname varchar(40),
      description varchar(128),
      who_to_ask varchar(40),
      os_name varchar(20),
      os_release_full varchar(20),
      kernel varchar(10),
      kernelrelease varchar(40),
      memory_swap_total_bytes bigint,
      uptime_hours int,
      last_updated text DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (hostname, domainname)
        ON CONFLICT FAIL
    );'
}


# Create the network interfaces table.
#
# The database needs separate tables for those system resources that
# might occur many times, like network interfaces or disks. Creating
# tables for these resources should use a primary key and foreign key
# scheme similar to the one shown here.
#
# The column "interface_type" is Ethernet, Infiniband, Fiber Channel,
# etc.
#
# Usage: `fn_libitil_create_table_interfaces
fn_libitil_create_table_interfaces () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS interfaces (
      system_serial_number
        REFERENCES systems (serial_number)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      interface_name varchar(10),
      interface_type varchar(20),
      interface_mac_address varchar(20),
      last_updated text DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY
        (system_serial_number,
        interface_name)
        ON CONFLICT FAIL
    );'
}


# Create the notes table.
#
# The notes table is for soft notes about a host, like a system 
# description, warnings, and the name of the person with primary
# interest in the host.
#
# Usage: `fn_libitil_create_table_notes`
fn_libitil_create_table_notes () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS notes (
      hostname varchar(20)
        REFERENCES hosts (hostname)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      domainname varchar(40)
        REFERENCES hosts (domainname)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      description varchar(128),
      who_to_ask varchar(128),
      warnings varchar(128),
      last_updated text DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (hostname, domainname)
        ON CONFLICT FAIL
    );'
}


# Create the systems table.
#
# The systems table is basic hardware information. Aside from
# serial_number, hostname, and domainname, column names match the
# equivalent names in Puppet. This table could be dropped in favor
# of a read-only API connecting to Puppet for the facts of a given
# host. (No sense in duplicating the data if it's over there and
# accessible.)
#
# The "serial_number" field could be set to whatever external
# hardware serial number system is in use.
#
# Usage: `fn_libitil_create_table_systems`
fn_libitil_create_table_systems () {
  ${e_sqlite3} ${df_itildb} 'CREATE TABLE IF NOT EXISTS systems (
      serial_number INTEGER PRIMARY KEY ASC AUTOINCREMENT,
      hostname varchar(20)
        REFERENCES hosts (hostname)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
      domainname varchar(40)
        REFERENCES hosts (domainname)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
      virtual varchar(10),
      processors_count smallint,
      processors_isa varchar(10),
      processors_physicalcount tinyint,
      memory_system_total_bytes bigint,
      last_updated text DEFAULT CURRENT_TIMESTAMP
    );'
}

# Get the hostname
#
# This function will take an FQDN and return the simple hostname.
#
# Usage: `fn_libitil_get_hostname <FQDN>`
fn_libitil_get_hostname () {
  local s_fqdn=${1:-}

  if [ -z "${s_fqdn}" ]
  then
    return 1
  fi

  echo $( expr ${s_fqdn} : '\([^.][^.]*\)\..*' )
}


# Get the domainname
#
# This function will take an FQDN and return the domain portion.
#
# Usage: `fn_libitil_get_domainname <FQDN>`
fn_libitil_get_domainname () {
  local s_fqdn=${1:-}

  if [ -z "${s_fqdn}" ]
  then
    return 1
  fi

  echo $( expr ${s_line} : '[^.][^.]*\.\(.*\)' )
}
