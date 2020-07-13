#!/usr/bin/python
#
# getFacts.py
#
# This script will loop through all Puppet Enterprise servers listed in
# the array a_pe_servers, collect their inventories, and combine
# selected information from the inventories into a single SQLite
# database file specified by the variable df_sqlite.
#
# This script is intended to run as a cron job, updating the database
# to current information with each execution.
#
#
# 2020-02-12 David Barr
# Initial script completed.
#
#

import commands, json, re, sqlite3

###
### EXPLICIT VARIABLES
###

# SQLite Database to keep the output.
df_sqlite = '/usr/local/lib/itil/itil.sqlite'


# Set list of Puppet Enterprise servers.
a_pe_servers = [ 
                 "puppet.dev.example.com",
                 "puppet.test.example.com",
                 "puppet.prod.example.com",
               ]

###
### FUNCTIONS
###

# Inserts or updates a row in the hosts table.
#
# hostsTableList = [
#                    s_hostname,
#                    s_domainname,
# (Puppet env.)      s_environment,
#                    s_osName,
#                    s_osReleaseFull,
#                    s_kernel,
#                    s_kernelRelease,
#                    i_memorySwapTotalBytes
#                    i_upHours
#                  ]
#
# Usage: `update_hosts_table( <List hostsTableList> )`
def update_hosts_table( hostsTableList ):

  cmd = "INSERT OR REPLACE INTO hosts "
  cmd = cmd + "( hostname, domainname, environment, os_name, "
  cmd = cmd + "os_release_full, kernel, kernelrelease, "
  cmd = cmd + "memory_swap_total_bytes, uptime_hours ) VALUES ( "
  cmd = cmd + "\"" + hostsTableList[0] + "\", "
  cmd = cmd + "\"" + hostsTableList[1] + "\", "
  cmd = cmd + "\"" + hostsTableList[2] + "\", "
  cmd = cmd + "\"" + hostsTableList[3] + "\", "
  cmd = cmd + "\"" + hostsTableList[4] + "\", "
  cmd = cmd + "\"" + hostsTableList[5] + "\", "
  cmd = cmd + "\"" + hostsTableList[6] + "\", "
  cmd = cmd + str(hostsTableList[7]) + ", "
  cmd = cmd + str(hostsTableList[8]) + " );"

  #print cmd
  db_cursor.execute( cmd )

  
# Inserts a row in the notes table, or leaves a matching row unchanged.
#
# notesTableList = [
#                    s_hostname,
#                    s_domainname,
#                  ]
#
# Usage: `update_hosts_table( <List hostsTableList> )`
def update_notes_table( notesTableList ):

  cmd = "INSERT OR IGNORE INTO notes "
  cmd = cmd + "( hostname, domainname ) VALUES ( "
  cmd = cmd + "\"" + notesTableList[0] + "\", "
  cmd = cmd + "\"" + notesTableList[1] + "\" ); "

  #print cmd
  db_cursor.execute( cmd )


# Inserts or updates a row in the systems table.
#
# systemsTableList = [
#                      s_hostname,
#                      s_domainname,
#                      s_virtual,
#                      i_processorsCount,
#                      s_processorsISA,
#                      i_processorsPhysicalCount,
#                      i_memorySystemTotalbytes,
#                    ]
#
# Usage: `update_systems_table( <List systemsTableList> )`
def update_systems_table( systemsTableList ):

  cmd = "INSERT OR REPLACE INTO systems "
  cmd = cmd + "( hostname, domainname, virtual, "
  cmd = cmd + "processors_count, processors_isa, "
  cmd = cmd + "processors_physicalcount, memory_system_total_bytes ) "
  cmd = cmd + "VALUES ( \""
  cmd = cmd + systemsTableList[0] + "\", \""
  cmd = cmd + systemsTableList[1] + "\", \""
  cmd = cmd + systemsTableList[2] + "\", "
  cmd = cmd + str(systemsTableList[3]) + ", \""
  cmd = cmd + systemsTableList[4] + "\", "
  cmd = cmd + str(systemsTableList[5]) + ", "
  cmd = cmd + str(systemsTableList[6]) + " );"

  #print cmd
  db_cursor.execute( cmd )


# Get a list of hosts and associated facts from a specified Puppet
# server.
#
# Usage: `get_puppet_entries( <Puppet server FQDN>)`
def get_puppet_entries( puppetServer ):
  cmd = "ssh -q " + puppetServer
  cmd = cmd + ' "curl http://localhost:8080/pdb/query/v4/inventory 2>/dev/null"'

  #print cmd
  try:
    results = json.loads( commands.getoutput( cmd ) )
  except ValueError as err:
    error = puppetServer + " failed to return elements: "
    error = error + str(err) + "."
    raise IOError(error)

  for i, entry in enumerate(results):
    s_fqdn = entry['certname']
    a_fqdnList = re.split("\.", s_fqdn, 1)
    s_hostname = a_fqdnList[0]
    s_domainname = a_fqdnList[1]

    try :
      i_memorySwapTotalBytes = entry['facts']['memory']['swap']['total_bytes']
    except:
      i_memorySwapTotalBytes = 0

    try:
      i_memorySystemTotalBytes = entry['facts']['memory']['system']['total_bytes']
      i_processorsCount = entry['facts']['processors']['count']
      i_processorsPhysicalCount = entry['facts']['processors']['physicalcount']
      i_upHours = entry['facts']['system_uptime']['hours']
      s_environment = entry['environment']
      s_kernel = entry['facts']['kernel']
      s_kernelRelease = entry['facts']['kernelrelease']
      s_osName = entry['facts']['os']['name']
      s_osReleaseFull = entry['facts']['os']['release']['full']
      s_processorsISA = entry['facts']['processors']['isa']
      s_virtual = entry['facts']['virtual']
  
    except KeyError as s_err:
      msg = s_fqdn + " (" + puppetServer + ") did not return a value "
      msg = msg + "for " + str(s_err) + "."
      raise KeyError( msg )
    except:
      raise IOError( s_fqdn + ' did not return information as expected.' )


    print "System: " + s_fqdn + ", Uptime: " + str(i_upHours)

    update_hosts_table( [
                          s_hostname,
                          s_domainname,
                          s_environment,
                          s_osName,
                          s_osReleaseFull,
                          s_kernel,
                          s_kernelRelease,
                          i_memorySwapTotalBytes,
                          i_upHours
                        ])

    update_notes_table( [
                            s_hostname,
                            s_domainname,
                            None,
                            None,
                            None,
                        ])

    update_systems_table( [
                            s_hostname,
                            s_domainname,
                            s_virtual,
                            i_processorsCount,
                            s_processorsISA,
                            i_processorsPhysicalCount,
                            i_memorySystemTotalBytes
                          ])
    db.commit()
  
###
### MAIN
###

db = sqlite3.connect( df_sqlite )
db_cursor = db.cursor()

for s_host in a_pe_servers:
#for s_host in [ "puppet.dev.example.com" ]:
  get_puppet_entries( s_host )

db.close()

