# motd Info

motd Info generates a dynamic motd via shell scripts. It is easily configurable.

## Principles

motd Info follows the following principles:

- information is displayed with as little characters as possible while still easily readable
  - this also means having sufficient blank space inbetween
- bad values stand out more than good ones
- dates are [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601)
- times specify the time zone

## Example

![example](./example.png)

## Setup

1. copy this folder to `/usr/local/src/motd-info/`
   perhaps excluding `.git`
   the folder does not have to be owned by root  
   (location as per the [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html))
2. create a symlink to the generate script in the `update-motd.d` directory:  
   `sudo ln -s /usr/local/src/motd-info/generate.sh /etc/update-motd.d/09-motd-info`
3. check what other motd scripts are in `/etc/update-motd.d/` and delete the unwanted ones (probably all)
4. configure `config.txt` to change the layout
5. configure widgets
6. if using lastlogins widget (default): Disable sshd's last login prompt by setting the `PrintLastLog` flag to `no` in `/etc/ssh/sshd_config`. Be aware of the implications explained below.

### Widgets

Check the widget files for config options.

This chapter does not list all widgets, only ones that require special attention.

#### apt

You may want to install needsrestart to be notified of required restarts due to library upgrades.
Check the widget for more info.

#### lastlogins

If you want to use the lastlogin widget:

- lastlogins shows a list of the N most recently logged in users. This does not necessarily include you.
  - This is because motd is user agnostic.
- motd may be pregenerated and cached, hence the info may be stale.
- Disable sshd's last login prompt by setting the `PrintLastLog` flag to `no` in `/etc/ssh/sshd_config`.

#### lastexec

lastexec may be useful on systems where motd is cached (e.g. Ubuntu) to see how old the information is.

## Development

### Test Environment

- test in motd environment: `/usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ./generate.sh`
  - actual motd environment is run as root
- execute all system motd scripts: `run-parts --lsbsysinit /etc/update-motd.d`
- execute all system motd scripts in motd environment: `/usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin run-parts --lsbsysinit /etc/update-motd.d`
  - actual motd environment is run as root

(taken from [Stack Overflow](https://stackoverflow.com/a/53889312/11391248))

### Update Frequency

The motd displayed at login may not be up to date. Depending on the system, it is pre-generated and then cached for a while.

Ubuntu caches it. Proxmox does not. Any others I don't know.

### Script Naming

The script (or symlink) in `/etc/update-motd.d/` must have a filename that satisfies:

- starting with a two digit number: dd-xxxxxx
- only lower-case letters, digits, '-', '_'
- no extension (as '.' is not allowed), no caps, 00-xxxxxxx

Check whether your script would run (outputs list of all scripts that would run without running them):  
  `run-parts --test --lsbsysinit /etc/update-motd.d`

## Other motd

This motd was inspired by BDR's [tinymod](https://github.com/bderenzo/tinymotd).

Other informational motd:

- [tinymotd](https://github.com/bderenzo/tinymotd) by BDR
- [ssh-motd](https://github.com/brombomb/ssh-motd) by Rob Walsh
- [dynamic-motd](https://github.com/ldidry/dynamic-motd) by Luc Didry
- [proxmox-motd](https://github.com/voklab/proxmox-motd) by Kevin Vo

## Further Reading

See [motd.md](./motd.md).
