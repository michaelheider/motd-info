# motd

This document contains more info on the workings of motd. It goes into some detail.

## How It Works

motd (Message of the Day) is the text that pops up automatically after logging in via terminal. It displays dynamic and static information.

`/etc/motd` and `/etc/motd.d/*` hold the static part of the motd. By default, `/etc/motd` is Debian's license information.

The dynamic part comes from the scripts in `/etc/update-motd.d/` and is put into `/run/motd.dynamic`. You can execute the scripts to see what their specific output is. You can execute all scripts in order with `run-parts /etc/update-motd.d/`.

`pam_motd` executes the scripts and displays the static motd files at login. On Proxmox, the motd scripts are executed on every login, other systems may cache the scripts' results.

## Further Reading

- [Debian wiki](https://wiki.debian.org/motd)
- [Ubuntu Manpage](https://manpages.ubuntu.com/manpages/trusty/en/man5/update-motd.5.html)

## Remarks on Certain Systems

### sshd Remark

> sshd has its own option "?PrintMotd" in /etc/ssh/sshd\_config. This defaults to "yes", but is set to "no" in Debian's default configuration since you get the motd twice otherwise: Once printed by pam_motd, the second time by sshd itself. Please note that the motd doesn't show on multiplexed ssh connections, only on the "first" session that also does the authentication.

([Debian wiki](https://wiki.debian.org/motd#sshd))

### Ubuntu Remark

On Ubuntu, the motd is cached. Hence, it is not regenerated on every login. It maybe slightly stale. This is also annoying for testing. The apt package update-motd is not installed by default.

Ubuntu additionally comes with motd-news from the apt package motd-news-config. Its config is in `/etc/default/motd-new`. It runs the `motd-news.service` and `motd-news.timer`. You can disable it in its config.

### Proxmox Remark

Proxmox's pvebanner service displays a banner on login via direct access. Not via SSH.

Some sources on the internet report interference with motd, but I cannot verify this.
