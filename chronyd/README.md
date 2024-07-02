# Notes on chronyd

## 2024-07-02

The NTP authentication link has rotted away. So, here are links to the
RHEL 9 documentation for [chrony][240702a] and
[Network Time Security][240702b].

[240702a]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/configuring-time-synchronization_configuring-basic-system-settings#using-chrony-to-configure-ntp_configuring-time-synchronization
[240702b]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/configuring-time-synchronization_configuring-basic-system-settings#assembly_overview-of-network-time-security-in-chrony_configuring-time-synchronization


## 2021-12-03

The chronyd equivalent of `ntpq -pn` is `chronyc sources -v`. (I don't
believe I needed this long to make that note, this being at least the
third time I had to go look that up! :roll_eyes:[^1])

[^1]: Text-to-emoji: https://github.com/ikatyang/emoji-cheat-sheet/blob/master/README.md


## 2021-07-06

### Using authentication for NTP calls

https://www.tekfik.com/kb/linux/chrony-symmetric-authentication

