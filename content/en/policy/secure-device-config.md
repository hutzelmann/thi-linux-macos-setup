---
title: Secure device configuration
description: What the university requires of a work computer, and what each rule means on Linux and macOS.
status: imported
os: [arch, debian, macos]
---

# Secure device configuration

The rules that apply to university-owned computers. They are written for Windows, which
leaves the Linux and macOS equivalents to interpretation — that interpretation is the
point of this page.

::: warning This page is not authoritative
The requirements come from a letter from the university management. Where this page and
the official text disagree, the official text is what counts, and it is the version you
should read: search MyTHI for *"sicher an der THI"*, or see
[IT-Sicherheitsrichtlinien](https://help.thi.de/help/de-de/1-it/177-it-sicherheitsrichtlinien).
Nobody here has confirmed that the mappings below satisfy an audit.
:::

## The requirements

As stated:

- The **hostname matches the sticker** on the front of the device (`IF…` inventory
  format).
- The **guest account is disabled**.
- The **firewall is enabled**. Only individual necessary services may be opened; a
  blanket allow is not permitted.
- A **virus scanner** is active, with current definitions. On Windows service machines
  this is Microsoft Defender.
- The system is **connected to the campus network regularly** — once a month for four
  hours without interruption — so operating-system and software updates install.
- The **local disk is encrypted**.
- Incoming connections without prior initialisation are blocked.

## What each one means on Linux

::: os arch

| Requirement | On Arch |
|---|---|
| Hostname matches sticker | `hostnamectl set-hostname <inventarnummer>` |
| Guest account disabled | No guest account exists by default. Nothing to do. |
| Firewall, default deny inbound | `ufw` or `firewalld`; `ufw default deny incoming` matches the wording closely |
| Disk encryption | LUKS on the root volume, normally chosen at install |
| Regular updates | `pacman -Syu` regularly; the four-hours-on-campus rule is about Windows update delivery and has no direct equivalent |
| Virus scanner | See below |

:::

::: os debian

| Requirement | On Debian |
|---|---|
| Hostname matches sticker | `hostnamectl set-hostname <inventarnummer>` |
| Guest account disabled | No guest account by default |
| Firewall, default deny inbound | `ufw enable` with `ufw default deny incoming` |
| Disk encryption | LUKS, offered by the installer |
| Regular updates | `unattended-upgrades` covers this properly |
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

The requirement names Microsoft Defender because it is written for Windows. On Linux
there is no equivalent expectation from the distributions themselves, and the policy text
says explicitly that ignoring this point on Linux is at your own risk.

That leaves you with a judgement call rather than a command to run. `clamav` exists and
is what most people reach for when a checkbox needs ticking; whether it meaningfully
improves the security of a Linux workstation is a separate question from whether it
satisfies an auditor.

This page cannot resolve that for you. If you have a written answer from IT about what
satisfies the requirement on Linux, it would be the single most useful contribution to
this page.

---

::: info Imported notes
Requirements transcribed from the policy; the per-OS mappings are this project's
interpretation and have not been confirmed by anyone official. Treat them as a starting
point for a conversation, not as compliance.
:::
