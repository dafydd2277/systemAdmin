# local_firewall::post
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include local_firewall::post
class local_firewall::linux::post {

  firewall {'945 drop broadcasts not already accepted.':
    action  => 'drop',
    chain   => 'INPUT',
    pkttype => 'broadcast',
    proto   => 'all',
  }

  # See https://en.wikipedia.org/wiki/Echo_Protocol
  firewall {'950 drop tcp to ECHO port':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '7',
    proto  => 'tcp',
  }

  firewall {'951 drop udp to ECHO port':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '7',
    proto  => 'udp',
  }

  firewall {'955 drop bootp tcp':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '67-68',
    proto  => 'tcp',
  }

  firewall {'956 drop bootp udp':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '67-68',
    proto  => 'udp',
  }

  firewall {'960 drop netBIOS tcp':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '137-138',
    proto  => 'tcp',
  }

  firewall {'961 drop netBIOS udp':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '137-138',
    proto  => 'udp',
  }

  firewall {'965 drop Microsoft Directory Services tcp':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '445',
    proto  => 'tcp',
  }

  firewall {'966 drop Microsoft Directory Services udp':
    action => 'drop',
    chain  => 'INPUT',
    dport  => '445',
    proto  => 'udp',
  }

  firewall {'975 accept ICMP ping':
    action => 'accept',
    chain  => 'INPUT',
    icmp   => 'echo-request',
    proto  => 'icmp',
  }

  firewall {'980 drop other ICMP':
    action => 'drop',
    chain  => 'INPUT',
    icmp   => undef,
    proto  => 'icmp',
  }

  firewall {'985 drop basic multicast':
    action      => 'drop',
    chain       => 'INPUT',
    destination => '224.0.0.1/32',
    proto       => 'all',
  }

  firewall {'990 log the remainder':
    chain      => 'INPUT',
    jump       => 'LOG',
    limit      => '4/min',
    log_level  => 'info',
    log_prefix => 'Dropped by iptables:',
    proto      => 'all',
  }

  firewall {'996 reject all privileged tcp':
    action => 'reject',
    chain  => 'INPUT',
    dport  => '0-1024',
    proto  => 'tcp',
    reject => 'icmp-port-unreachable',
  }

  firewall {'997 reject all privileged udp':
    action => 'reject',
    chain  => 'INPUT',
    dport  => '0-1024',
    proto  => 'udp',
    reject => 'icmp-port-unreachable',
  }
}
