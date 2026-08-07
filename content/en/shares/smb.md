---
title: Network shares (SMB)
description: Mount your campus home directory and group shares on Arch, Debian and macOS, on campus or over VPN.
status: structured
os: [arch, debian, macos]
---

# Network shares (SMB)

Gets you your campus home directory and any group shares as folders on your machine.

Official documentation: [connecting a network drive](${facts.shares.official_url}).

## Before you start

These servers only exist inside the campus network. From anywhere else, connect the
[VPN](/en/vpn/openfortivpn) first — everything below fails with a name-resolution error
otherwise, which looks like a configuration mistake and is not one.

## Documented values

| | |
|---|---|
| Home directory | `smb://${facts.shares.home_server}/<kennung>` |
| Group and departmental shares | `smb://${facts.shares.file_server}/` |
| Research shares (CARISSMA) | `smb://${facts.shares.research_server}/` |
| Domain | `${facts.shares.domain}` |
| Username | your campus login (`<kennung>`) |

Some clients have no separate domain field. Those want the two combined:
`${facts.shares.domain}\<kennung>`.

## The click path

No terminal needed, and this is the better option for occasional access — the connection
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

Useful when you want the share at a fixed path — for scripts, backups or a build that
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

`uid` and `gid` matter on Linux: without them the mount belongs to root and your editor
cannot write to it.

Unmount with `sudo umount ~/mnt/thi-home` (`umount` without `sudo` on macOS).

## Verify

<ScriptDownload file="shares-verify.sh" does="Says whether the file servers are reachable from where you are" />

It answers the question people actually have — *is it me, the VPN, or the server?* No
credentials are used and nothing is mounted.

By hand:

```bash
getent hosts ${facts.shares.home_server}
```

No output means the name does not resolve, which means you are not on the campus network
and the VPN is not up.

## Known quirks

**Do not put your password in `/etc/fstab`.** The usual advice is a credentials file with
mode `600`, and it still writes your SSO password to disk in clear text — the password
that also reaches your mail and your grades. Mount on demand instead, or use a keyring.

**A stale mount hangs everything that touches it.** If the VPN drops while a share is
mounted, `ls` in that directory can block for minutes. `sudo umount -l ~/mnt/thi-home`
detaches it immediately.

**Share names beyond the servers above are not documented here.** If you know the layout
of the group shares, that is a genuinely useful addition.
