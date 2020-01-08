# local_sysctl
#
# This classes uses a forge module to control sysctl settings.
#
# https://forge.puppet.com/herculesteam/augeasproviders_sysctl
#
# Hiera Entry:
#
# local_sysctl:
#   <control name>:
#     ensure: <present|absent>   # Anything not 'absent' is present.
#     value: String              # Required if present
#     comment: String
#     target: <destination file> # Default: /etc/sysctl.d/00-puppet-default.conf
#     persist: <true|false>      # Persist the change across reboots. Default: true.
#   kernel_sysreq:
#     ensure: present
#     value: 0
#     comment: 'Controls the System Request debugging functionality of the kernel'
#     
# @summary Set sysctl values in Puppet
#
# @example
#   include local_sysctl
class local_sysctl {

  # Loop through the sysctl settings in hiera.
  $hash_sysctl=lookup({'name' => 'local_sysctl',
                    'merge' =>
                      { 'strategy'           => 'deep',
                        'sort_merged_arrays' => true,
                        'merge_hash_arrays'  => true,
                      },
                    })

  $hash_sysctl.each | String $name, Hash $elements | {
  
    # Set the target file.
    if empty($elements['target']) {
      case $facts['os']['release']['major'] {
        '5': {
          $s_target = '/etc/sysctl.conf'
        }
        default: {
          $s_target = '/etc/sysctl.d/00-puppet-default.conf'
        }
      }
    }
    else {
      $s_target = $elements['target']
    }

    # Set the comment string.
    if empty($elements['comment']) {
      $s_comment = ''
    }
    else {
      $s_comment = $elements['comment']
    }


    # Any $elements['ensure'] not explicitly absent is present.
    case $elements['ensure'] {
      'absent': {
        sysctl { $name :
          ensure => absent,
        }
      }
      default: {
        # Any $elements['persist'] not explicitly false, including
        # a blank or missing setting, is true.
        case $elements['persist'] {
          false: {
            sysctl { $name :
              ensure  => present,
              value   => $elements['value'],
              comment => $s_comment,
              persist => false,
              target  => $s_target,
            }
          }
          default: {
            sysctl { $name :
              ensure  => present,
              value   => $elements['value'],
              comment => $s_comment,
              target  => $s_target,
            }
          }
        }
      }
    }
  }
}
