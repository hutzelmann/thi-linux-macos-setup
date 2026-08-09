---
title: Secure device configuration on Linux and macOS
description: What the university requires of a work computer, and what each rule means on Linux and macOS.
os: [arch, debian, macos]
---

# Secure device configuration

The rules that apply to university-owned computers. They are written for Windows, which
leaves the Linux and macOS equivalents to interpretation. That interpretation is the
point of this page.

::: warning This page is not authoritative
The requirements come from a letter from the university management. What follows is one
reading of that letter, written without authority to interpret it and without liability
for the consequences. Where this page and the official text disagree, the official text
is what counts, and it is the version you should read: search MyTHI for
*"sicher an der THI"*, or see
[IT-Sicherheitsrichtlinien](${facts.official.kb_url}/1-it/177-it-sicherheitsrichtlinien).
:::

## The requirements

As stated:

- The **local disk is encrypted**.
- The **hostname matches the sticker** on the front of the device (`IF…` inventory
  format).
- The **guest account is disabled**.
- The **firewall is enabled** and incoming connections without prior initialisation are
  blocked. Only individual necessary services may be opened; a blanket allow is not
  permitted.
- A **virus scanner** is active, with current definitions. On Windows service machines
  this is Microsoft Defender.
- The system is **connected to the campus network regularly**, once a month for four
  hours without interruption, so operating-system and software updates install.

Getting a machine onto that network is
[eduroam and @thi Wi-Fi](/en/wifi/) or
[wired Ethernet with 802.1X](/en/network/ethernet-802-1x).

## What each one means on your system

::: os arch

| Requirement | On Arch |
|---|---|
| Hostname matches sticker | `hostnamectl set-hostname <inventarnummer>` |
| Guest account disabled | No guest account exists by default. Nothing to do. |
| Firewall, default deny inbound | `ufw` or `firewalld`; `ufw default deny incoming` matches the wording closely |
| Disk encryption | LUKS on the root volume, normally chosen at install |
| Regular updates | `pacman -Syu` regularly |
| Virus scanner | See below |

:::

::: os debian

| Requirement | On Debian |
|---|---|
| Hostname matches sticker | `hostnamectl set-hostname <inventarnummer>` |
| Guest account disabled | No guest account by default |
| Firewall, default deny inbound | `ufw enable` with `ufw default deny incoming` |
| Disk encryption | LUKS, offered by the installer |
| Regular updates | `apt update && apt upgrade` regularly, or the `unattended-upgrades` package to apply security updates on its own once enabled. Setup and configuration: [PeriodicUpdates on the Debian Wiki](https://wiki.debian.org/PeriodicUpdates) |
| Virus scanner | See below |

:::

::: os macos

| Requirement | On macOS |
|---|---|
| Hostname matches sticker | System Settings → General → About → Name |
| Guest account disabled | System Settings → Users & Groups → Guest User → off |
| Firewall | System Settings → Network → Firewall → on |
| Disk encryption | FileVault |
| Regular updates | Automatic updates enabled |
| Virus scanner | XProtect is built in and always on |

:::

## The virus scanner question

The requirement names Microsoft Defender because it is written for Windows. It does not
say what the equivalent is anywhere else, and this page cannot settle that.

::: os arch

There is no equivalent expectation from the distributions themselves, and the policy text
says explicitly that ignoring this point on Linux is at your own risk. That leaves a
judgement call rather than a command to run.

ClamAV is the open-source scanner most people reach for when a checkbox needs ticking. By
default it scans on demand, so nothing is examined until something asks it to; continuous
scanning is a separate service on top. Whether that meaningfully improves the security of
a Linux workstation is a different question from whether it satisfies an auditor.

Setup, the `clamav-daemon` and `clamav-freshclam` services, and how to turn on
continuous scanning: [ClamAV on the ArchWiki](https://wiki.archlinux.org/title/ClamAV).

:::

::: os debian

There is no equivalent expectation from the distributions themselves, and the policy text
says explicitly that ignoring this point on Linux is at your own risk. That leaves a
judgement call rather than a command to run.

ClamAV is the open-source scanner most people reach for when a checkbox needs ticking. By
default it scans on demand, so nothing is examined until something asks it to; continuous
scanning is a separate service on top. Whether that meaningfully improves the security of
a Linux workstation is a different question from whether it satisfies an auditor.

Setup, the `clamav-daemon` and `clamav-freshclam` services, and how to turn on
continuous scanning: [ClamAV on the Debian Wiki](https://wiki.debian.org/ClamAV).

:::

::: os macos

macOS ships XProtect, which Apple maintains and which runs without being installed or
switched on. Whether that is what the requirement means by a virus scanner is the same
open question as on Linux. The difference is that there is nothing for you to do either
way.

:::

## Verify

There is no compliance check to run. Nothing here reports to anyone, and this page cannot
tell you whether an auditor would agree. What you can do is confirm each setting is in the
state you think it is:

::: os arch

```bash
hostnamectl                          # name matches the sticker
sudo ufw status verbose              # active, default deny incoming
lsblk -o NAME,TYPE,MOUNTPOINTS,FSTYPE # look for crypto_LUKS on the root device
```

:::

::: os debian

```bash
hostnamectl
sudo ufw status verbose
lsblk -o NAME,TYPE,MOUNTPOINTS,FSTYPE
systemctl status unattended-upgrades
```

:::

::: os macos

```bash
scutil --get ComputerName
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
fdesetup status                      # FileVault
softwareupdate --schedule
```

:::

## Known quirks

**The monthly four-hour rule is about Windows update delivery.** It exists so managed
Windows machines get their updates from campus infrastructure. On Linux and macOS the
equivalent obligation is simply keeping the system current, which you do anyway, but the
policy text does not say that, and this page cannot say it on the policy's behalf.
