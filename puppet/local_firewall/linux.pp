# local_firewall::linux
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include local_firewall::linux
class local_firewall::linux {

  # Manage running/stopped ipv6 via $ensure_v6
  # Explictily stop managing ebtables through the Forge firewall module.
  class { 'firewall':
    ebtables_manage => false,
    ensure_v6       => $local_firewall::ensure_v6,
  }

  # ip6tables was deprecated in RHEL 7.
  file { [
            '/etc/sysconfig/ip6tables.save',
            '/etc/sysconfig/ip6tables-config',
  ]:
    ensure  => absent,
    require => Service['ip6tables'],
  }


  # ebtables was deprecated in RHEL 7.
  service { 'ebtables':
    ensure => stopped,
    enable => false,
  }

  file { [  '/etc/sysconfig/ebtables',
            '/etc/sysconfig/ebtables.save',
            '/etc/sysconfig/ebtables-config',
  ]:
    ensure  => absent,
    require => Service['ebtables'],
  }


  # Note that iptables must be running before the pre class is
  # executed.
  class {'local_firewall::linux::pre':
    require => Service[ 'iptables', ],
  }

  class {'local_firewall::linux::post':
  }


  # Tell the Forge firewall module to clear everything not managed by
  # Puppet.
  resources { 'firewall':
    purge => true,
  }
  #resources { 'firewallchain':
  #  purge => true,
  #}


  # Set the pre and post classes for inclusion.
  Firewall {
    before  => Class['local_firewall::linux::post'],
    require => Class['local_firewall::linux::pre'],
  }


  # Accept anything across private networks. `has_interface_with` is
  # part of the Puppet STDLIB. Any named interface will work.
  if has_interface_with('bondeth1') {
    firewall {'005 accept bondeth1 interface':
      action  => 'accept',
      chain   => 'INPUT',
      iniface => 'bondib0',
      proto   => 'all',
    }
  }


  # Loop through the ports accepted in hiera. A hiera yaml entry looks
  # like this:
  #
  # local_firewall_accepts:
  #   '150':
  #     description: 'Accept Oracle DB Connections'
  #     port: '1521'
  #     protocol: 'tcp'
  #
  $hash_accepts=lookup({'name' => 'local_firewall_accepts',
                    'merge' =>
                      { 'strategy'           => 'deep',
                        'sort_merged_arrays' => true,
                        'merge_hash_arrays'  => true,
                      },
                    })

  $hash_accepts.each | String $rule, Hash $elements | {
    if ( $elements['port'] != '' ) {
      firewall {"${rule} ${elements['description']}":
        action => 'accept',
        chain  => 'INPUT',
        dport  => $elements['port'],
        proto  => $elements['protocol'],
      }
    }
    else {
      firewall {"${rule} ${elements['description']}":
        action => 'accept',
        chain  => 'INPUT',
        proto  => $elements['protocol'],
      }
    }
  }
}
