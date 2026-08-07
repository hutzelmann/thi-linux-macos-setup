---
title: Network shares (SMB)
description: Mounting the campus home directory and group shares from Linux and macOS.
status: imported
os: [arch, debian, macos]
---

# Network shares (SMB)

Gets you your campus home directory and any group shares. Requires the campus network or
an active [VPN](/en/vpn/openfortivpn) connection.

Official documentation: [connecting a network drive](${facts.shares.official_url}).

## Documented values

| | |
|---|---|
| Home directory | `smb://${facts.shares.home_server}/` |
| Group and departmental shares | `smb://${facts.shares.file_server}/` |
| Research shares (CARISSMA) | `smb://${facts.shares.research_server}/` |
| Domain | `${facts.shares.domain}` |
| Username | `<kennung>` |

Clients that have no separate domain field want the two combined:
`${facts.shares.domain}\<kennung>`.

## Connect

::: os arch

In a file manager, use *Connect to Server* with the URL above. From the terminal:

```bash
sudo pacman -S cifs-utils
sudo mount -t cifs //${facts.shares.home_server}/<kennung> /mnt/home-thi \
  -o username=<kennung>,domain=${facts.shares.domain},uid=$(id -u),gid=$(id -g)
```

:::

::: os debian

```bash
sudo apt install cifs-utils
sudo mount -t cifs //${facts.shares.home_server}/<kennung> /mnt/home-thi \
  -o username=<kennung>,domain=${facts.shares.domain},uid=$(id -u),gid=$(id -g)
```

:::

::: os macos

In Finder: **Go → Connect to Server** (`Cmd+K`), then the `smb://` URL above. Enter
`${facts.shares.domain}\<kennung>` as the username if prompted for a domain.

:::

## Known quirks

**Nothing resolves off campus.** These names only exist inside the campus network.
Connect the VPN first.

**Do not put your password in `/etc/fstab`.** A credentials file with mode `600` is the
usual approach, and it still puts your SSO password on disk in plain text — the same
password that reaches your mail and grades. Prefer mounting on demand.

---

::: info Imported notes
Collected from personal notes; not restructured or re-checked. Share names beyond the
servers listed here are not documented yet — if you know the layout of the group shares,
that would be a valuable addition.
:::
