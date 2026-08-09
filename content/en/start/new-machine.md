---
title: A new Linux or Mac machine on campus
description: The order to set up a Linux or Mac laptop for campus, from the device rules to network, printing and shares.
---

# A new machine on campus

The order to do things in. Each step links to the page with the detail; come back here
for what is next. No terminal needed, except where a page offers one as a faster route.

## 0. Check whether the device rules apply to you

[Secure device configuration](/en/policy/secure-device-config)

Only for university-owned hardware, the machine with an inventory sticker. Your own
laptop is not covered.

Read it before you install rather than after. Disk encryption, the hostname and the
firewall are all decided while you install.

**Skip if:** the laptop is yours.

## 1. Get online

[Wi-Fi: eduroam and @thi](/en/wifi/)

Use eduroam. It works here and at every other university, and needs no registration.

Set it up with the [configuration assistant](${facts.wifi.cat_url}) rather than by hand.
Hand-written profiles very often omit the check that stops a fake access point from
collecting your campus password, and the network works either way, so you would never
notice.

**Done when:** you are online, and the connection carries both a CA certificate and a
server name to match. The page has the command.

## 2. The wired network, only if you need it

[Ethernet: 802.1X and device registration](/en/network/ethernet-802-1x)

For Ethernet ports and docking stations. Most ports ask the machine to log in with your
campus login, which is four settings and no waiting. Some still check the adapter's
hardware address against a list, and getting onto that list is a form a human approves,
so start early if a port stays silent. A registration expires after
${facts.network.registration_validity}.

**Skip if:** you only use Wi-Fi.

**Done when:** you can switch Wi-Fi off and still open a web page over the cable.

## 3. VPN

[VPN from off campus](/en/vpn/openfortivpn)

Needed off campus for network shares and some library resources. One certificate step
once, because the gateway does not send its full chain; after that it is one command.

**Done when:** the tunnel comes up from off campus and an internal address answers,
such as a network share.

## 4. Printing

[Printing](/en/printing/)

The driver is a large manual download. In a hurry, skip it and use
[${facts.printing.webprint_url}](${facts.printing.webprint_url}) in the browser, with no
setup at all, at the cost of the finishing options (hole punching and stapling).

Either way the job waits on the server rather than at a printer, so the last step is
always yours: walk to a device and release it with your campus card.

**Done when:** a page you sent comes out of the device after you release it there.

## 5. Network shares

[Network shares (SMB)](/en/shares/smb)

Your home directory and any group shares, as folders on your machine. Campus network or
VPN only.

**Done when:** the file servers resolve from where you are. The page has a script that
answers that.

## Once that works

The rest of the site is not part of the setup order, and each page stands on its own.

- [OneDrive and Microsoft 365 on Linux](/en/files/onedrive), for the files that live in
  the university's Microsoft tenant rather than on a file server.
- [Windows 11 Education in a virtual machine](/en/vm/windows), for the handful of
  programs with no Linux version.
- [Projectors and external screens over HDMI](/en/devices/projectors), worth reading
  before the first time you plug into a lecture hall rather than five minutes into it.
