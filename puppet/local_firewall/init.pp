# local_firewall
#
# This module sets all firewall rules, including provision for
# customizing rules between the firewall::pre and firewall::post
# rule sets. See
#
# https://forge.puppet.com/puppetlabs/firewall
#
# for details. Additionally, role and profile specific port openings
# are handled via hiera variables. An example entry looks like this:
#
# local_firewall_accepts:
#   050:
#     description: 'accept SSH'
#     port: 22
#     protocol: tcp
#   466:
#      description: 'accept WebLogic 8888-8900/tcp'
#      port: '8888:8900',
#      protocol: 'tcp'
#
#
# The loop operation will combine the rule number ("050") with the
# description when it creates the `firewall` resource. Also, note that
# the an entry covering multiple ports uses the `firewall`-resource
# style separation of a colon character instead of a dash character.
#
# @summary This module sets all firewall rules.
#
# @example
#   include local_firewall
#
# @parameters
#   ensure_v6:           Provide on/off for ipv6
#                          if ensure_v6 = stopped, enable_v6 = false
#                          if ensure_v6 = running, enable_v6 = true
#
class local_firewall (

  ## Enable or disable firewall.
  Boolean $enable_firewall = true,

  ## Default turn off ipv6 -- manageable through hiera parameter
  ## ensure_v6 = stopped   => enable_v6 = false
  String  $ensure_v6 = 'stopped',

) {
  case $facts['kernel'] {
    'Windows' : {
      exec{'Disable Public Firewall':
      command => '$(Set-NetFirewallProfile -Name Public -Enabled False)',
      unless  => 'if ((Get-NetFirewallProfile -Name Public).Enabled -eq "False") {exit 0} Else {exit 1}',
      }

      exec{'Disable Private Firewall':
      command => '$(Set-NetFirewallProfile -Name Private -Enabled False)',
      unless  => 'if ((Get-NetFirewallProfile -Name Private).Enabled -eq "False") {exit 0} Else {exit 1}',
      }

      exec{'Disable Domain Firewall':
      command => '$(Set-NetFirewallProfile -Name Domain -Enabled False)',
      unless  => 'if ((Get-NetFirewallProfile -Name Domain).Enabled -eq "False") {exit 0} Else {exit 1}',
      }
    }
    'Linux' : {

      if $local_firewall::enable_firewall {
        include local_firewall::linux
      }
      else {
        service { 'iptables':
          ensure => stopped,
          enable => false,
        }

        service { 'ip6tables':
          ensure => stopped,
          enable => false,
        }

        service { 'ebtables':
          ensure => stopped,
          enable => false,
        }
      }
    }
    default : {
      notify {"${facts['kernel']} is not a supported operating system, firewall configuration will not be set" : }
    }
  }
}
