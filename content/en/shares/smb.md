---
title: Network shares (SMB) on Linux and macOS
description: Mount your campus home directory and group shares over SMB on Arch, Debian and macOS, in the file manager or with mount, on campus or over VPN.
os: [arch, debian, macos]
---

# Network shares (SMB)

Gets you your campus home directory and any group shares as folders on your machine, over
SMB: an `smb://` address in your file manager, or a mount command for a fixed path. Both
routes are below, for the system you picked at the top of this page.

Official documentation: [connecting a network drive](${facts.shares.official_url}).

## Before you start

These servers only exist inside the campus network. From anywhere else, connect the
[VPN](/en/vpn/openfortivpn) first. Everything below fails with a name-resolution error
otherwise, which looks like a configuration mistake and is not one.

## Documented values

| Setting | Value |
|---|---|
| Home directory | `smb://${facts.shares.home_server}/<kennung>` |
| Group and departmental shares | `smb://${facts.shares.file_server}/` |
| Research shares (CARISSMA) | `smb://${facts.shares.research_server}/` |
| Domain | `${facts.shares.domain}` |
| Username | your campus login (`<kennung>`) |

Some clients have no separate domain field. Those want the two combined:
`${facts.shares.domain}\<kennung>`.

## The click path

No terminal needed, and this is the better option for occasional access: the connection
disappears cleanly when you log out.

::: os arch

In Files (GNOME) or Dolphin (KDE), choose **Other Locations → Connect to Server** and
enter `smb://${facts.shares.home_server}/<kennung>`. Enter your login when prompted, and
`${facts.shares.domain}` as the domain.

:::

::: os debian

In Files (GNOME) or Dolphin (KDE), choose **Other Locations → Connect to Server** and
enter `smb://${facts.shares.home_server}/<kennung>`. Enter your login when prompted, and
`${facts.shares.domain}` as the domain.

:::

::: os macos

In Finder, **Go → Connect to Server** (`Cmd+K`), then
`smb://${facts.shares.home_server}/<kennung>`. If asked for a domain, use
`${facts.shares.domain}\<kennung>` as the user name instead.

Tick *Remember this password in my keychain* only on a machine that is yours alone.

:::

## The terminal path

Useful when you want the share at a fixed path, for scripts, backups or a build that
reads from it.

::: os arch

```bash
sudo pacman -S cifs-utils
mkdir -p ~/mnt/thi-home
sudo mount -t cifs //${facts.shares.home_server}/<kennung> ~/mnt/thi-home \
  -o username=<kennung>,domain=${facts.shares.domain},uid=$(id -u),gid=$(id -g)
```

:::

::: os debian

```bash
sudo apt install cifs-utils
mkdir -p ~/mnt/thi-home
sudo mount -t cifs //${facts.shares.home_server}/<kennung> ~/mnt/thi-home \
  -o username=<kennung>,domain=${facts.shares.domain},uid=$(id -u),gid=$(id -g)
```

:::

::: os macos

```bash
mkdir -p ~/mnt/thi-home
mount_smbfs "//${facts.shares.domain};<kennung>@${facts.shares.home_server}/<kennung>" \
  ~/mnt/thi-home
```

:::

::: os arch

`uid` and `gid` matter: without them the mount belongs to root and your editor cannot
write to it. Unmount with `sudo umount ~/mnt/thi-home`.

:::

::: os debian

`uid` and `gid` matter: without them the mount belongs to root and your editor cannot
write to it. Unmount with `sudo umount ~/mnt/thi-home`.

:::

::: os macos

The mount belongs to you already, so there is no `uid` to pass. Unmount with
`umount ~/mnt/thi-home`, no `sudo`.

:::

## Verify

<ScriptDownload file="shares-verify.sh" does="Says whether the file servers are reachable from where you are" />

It answers the question people actually have: *is it me, the VPN, or the server?* No
credentials are used and nothing is mounted.

By hand:

::: os arch

```bash
getent hosts ${facts.shares.home_server}
```

:::

::: os debian

```bash
getent hosts ${facts.shares.home_server}
```

:::

::: os macos

```bash
dscacheutil -q host -a name ${facts.shares.home_server}
```

:::

No output means the name does not resolve, which means you are not on the campus network
and the VPN is not up.

## Known quirks

**Do not put your password in `/etc/fstab`.** The usual advice is a credentials file with
mode `600`, and it still writes your SSO password to disk in clear text, the password
that also reaches your mail and your grades. Mount on demand instead, or use a keyring.

**A stale mount hangs everything that touches it.** If the VPN drops while a share is
mounted, `ls` in that directory can block for minutes.

::: os arch

`sudo umount -l ~/mnt/thi-home` detaches it immediately.

:::

::: os debian

`sudo umount -l ~/mnt/thi-home` detaches it immediately.

:::

::: os macos

`umount -f ~/mnt/thi-home` forces it loose. There is no lazy unmount here.

:::

**Share names beyond the servers above are not documented here.** If you know the layout
of the group shares, that is a genuinely useful addition.
