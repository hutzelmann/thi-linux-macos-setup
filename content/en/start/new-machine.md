---
title: A new machine on campus
description: The order to set up a Linux or Mac laptop for campus, from the device rules to network, printing and shares.
status: structured
os: [arch, debian, macos]
---

# A new machine on campus

A working order for a fresh laptop. Each step links to the full page; come back here
for what to do next.

Nothing here requires the command line except where a page offers it as a faster
alternative.

## 0. Check whether the device rules apply to you

[Secure device configuration](/en/policy/secure-device-config)

Only for university-owned hardware, the machine your department bought and that carries
an inventory sticker. Your own student or private laptop is not covered, so skip this
step and start at step 1.

If it is a work machine, read that page before you rebuild it: disk encryption, the
hostname, the firewall, and the requirement to connect to the campus network regularly
for updates all constrain how you install. Deciding them afterwards means reinstalling.

**Skip if:** the laptop is yours.

## 1. Get online

[Wi-Fi: eduroam and @thi](/en/wifi/)

Use eduroam. It works on campus and at every other university, and it needs no
registration.

Do it with the [configuration assistant](${facts.wifi.cat_url}) rather than by hand.
Hand-written profiles very often omit the check that stops a fake access point from
collecting your campus password, and the network works fine either way, so you would
never notice.

**Done when:** you are online, and
`nmcli -f 802-1x.domain-suffix-match connection show eduroam` prints a value.

## 2. Decide whether you need the wired network

[Wired ports and device registration](/en/network/ethernet-802-1x)

Only if you use an Ethernet port or a docking station. Registration is per MAC address,
takes a form submission, and is approved by a human, so start it early even if you
finish the rest first. It expires after ${facts.network.registration_validity}.

**Skip if:** you only ever use Wi-Fi.

## 3. VPN

[VPN from Linux and macOS](/en/vpn/openfortivpn)

Needed off campus for network shares and some library resources. There is a one-time
certificate step because the gateway does not send its full chain; after that it is one
command.

**Done when:** `./scripts/vpn/verify.sh` reports the chain verifies.

## 4. Printing

[Printing on ${facts.printing.queue}](/en/printing/marb-color)

The driver download is large and manual. If you are in a hurry, skip this entirely and
use [${facts.printing.webprint_url}](${facts.printing.webprint_url}) in a browser, with
no setup at all, at the cost of the finishing options.

**Done when:** `lpoptions -p ${facts.printing.queue} -l` lists `Pnch` and `Stpl`.

**Then:** send a job, walk to the device, and release it with your campus card. Nothing
prints until you do.

## 5. Network shares

[Network shares (SMB)](/en/shares/smb)

Your home directory and any group shares. Needs campus network or VPN.
