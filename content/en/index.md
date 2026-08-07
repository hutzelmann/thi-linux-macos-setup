---
layout: home
title: Linux and macOS at THI
titleTemplate: false
description: Community-maintained setup notes for Linux and macOS at Technische Hochschule Ingolstadt. Printing, Wi-Fi, VPN, network shares. Unofficial.

hero:
  name: Linux and macOS at THI
  tagline: Community setup notes for campus printing, Wi-Fi, VPN and shares. Unofficial, and not THI IT Support.
  actions:
    - theme: brand
      text: New machine, start here
      link: /en/start/new-machine
    - theme: alt
      text: How this works
      link: /en/about/how-this-works

features:
  - title: Wi-Fi
    details: eduroam and @thi, with the certificate settings that stop a fake access point from taking your password.
    link: /en/wifi/
  - title: Printing
    details: The MARB colour queue from CUPS — duplex, hole punching, stapling, and why nothing comes out until you tap your card.
    link: /en/printing/marb-color
  - title: VPN
    details: openfortivpn with SSO, including the certificate-chain fix the gateway needs.
    link: /en/vpn/openfortivpn
---

## Why this exists

Campus systems are documented for Windows. Most of it works on Linux and macOS too, but
the details — a driver path, a certificate authority, a hostname that changed last year —
are scattered across old mails, forum posts and personal notes.

This is that knowledge, written down in one place, in the open, so the next person does
not have to rediscover it.

**It is not official.** Nobody here speaks for university IT, nothing is guaranteed, and
there is no support desk behind it. For accounts, quotas and hardware, go to
[THI IT service](${facts.official.service_url}). What this project offers instead is a feedback loop:
if something here is wrong, [say so](https://github.com/hutzelmann/thi-linux-macos-setup/issues)
and it gets fixed.

Pages say when a human last checked them. Some say "nobody has checked this yet", because
that is the truth and pretending otherwise is worse.
