# local_firewall::pre
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include local_firewall::pre
class local_firewall::linux::pre {

  # Set the chains first.
  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    policy => drop,
  }

  firewallchain { 'FORWARD:filter:IPv4':
    ensure => present,
    policy => accept,
  }

  firewallchain { 'OUTPUT:filter:IPv4':
    ensure => present,
    policy => accept,
  }

  # Default prefix rules.
  firewall {'001 accept lo interface':
    action  => 'accept',
    chain   => 'INPUT',
    iniface => 'lo',
    proto   => 'all',
  }

  firewall {'002 reject local not from lo interface':
    action  => 'reject',
    chain   => 'INPUT',
    iniface => '! lo',
    proto   => 'all',
    source  => '127.0.0.1',
  }

  firewall {'003 reject local not to lo interface':
    action      => 'reject',
    chain       => 'INPUT',
    destination => '127.0.0.1',
    iniface     => '! lo',
    proto       => 'all',
  }

  # TCP SACK Panic
  # https://isc.sans.edu/forums/diary/What+You+Need+To+Know+About+TCP+SACK+Panic/25046/
  firewall {'006 REJECT packets with out-of-bounds MSS':
    action  => 'reject',
    chain   => 'INPUT',
    proto   => 'tcp',
    ctstate => 'NEW',
    mss     => '! 536:65535',
    reject  => 'icmp-admin-prohibited',
  }

  firewall {'015 accept related established':
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'all',
    state  => ['RELATED','ESTABLISHED',],
  }

  firewall {'020 drop NEW incoming packets with FIN/RST/ACK but not SYN':
    action    => 'drop',
    chain     => 'INPUT',
    proto     => 'tcp',
    state     => 'NEW',
    tcp_flags => '! FIN,SYN,RST,ACK SYN',
  }

  firewall {'021 accept reset acknowledgments':
    action    => 'accept',
    chain     => 'INPUT',
    proto     => 'tcp',
    tcp_flags => 'FIN,SYN,RST,PSH,ACK,URG RST,ACK',
  }

  firewall {'022 accept push acknowledgments':
    action    => 'accept',
    chain     => 'INPUT',
    proto     => 'tcp',
    tcp_flags => 'FIN,SYN,RST,PSH,ACK,URG PSH,ACK',
  }

  firewall {'025 drop malformed NULL packets':
    action    => 'drop',
    chain     => 'INPUT',
    proto     => 'tcp',
    tcp_flags => 'FIN,SYN,RST,PSH,ACK,URG NONE',
  }

  firewall {'030 drop fragments':
    action     => 'drop',
    chain      => 'INPUT',
    isfragment => true,
    proto      => 'all',
  }

  firewall {'035 accept NFS 111':
    action => 'accept',
    chain  => 'INPUT',
    dport  => '111',
    proto  => 'tcp',
  }

  firewall {'040 accept NFS 33100:33200':
    action => 'accept',
    chain  => 'INPUT',
    dport  => '33100-33200',
    proto  => 'tcp',
  }

  firewall {'045 accept NFS 36000:36100':
    action => 'accept',
    chain  => 'INPUT',
    dport  => '36000-36100',
    proto  => 'tcp',
  }

  firewall {'050 accept SSH':
    action => 'accept',
    chain  => 'INPUT',
    dport  => '22',
    proto  => 'tcp',
  }
}
