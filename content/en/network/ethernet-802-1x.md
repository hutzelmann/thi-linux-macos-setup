---
title: Wired ports and device registration
description: Registering a Linux or Mac device for campus Ethernet and the @thi network by MAC address, when the official onboarding client will not run.
status: structured
os: [arch, debian, macos]
---

# Wired ports and device registration

Gets a Linux or Mac device onto campus Ethernet ports, and onto the
`${facts.wifi.thi_ssid}` network. Both use the same registration, and it is the same form
either way.

Official documentation: [network sign-on](${facts.network.kb_url}) ·
[MyTHI: network and Wi-Fi on campus](${facts.network.official_url}) (login required).

::: tip You may not need this at all
[eduroam](/en/wifi/) needs no registration, works in every building, and works at other
universities too. Register a device when you specifically need a wired port or
`${facts.wifi.thi_ssid}`.
:::

## Why registration rather than the official client

Wired authentication is based on a whitelist of MAC addresses. The documented route is a
dedicated onboarding network and the vendor's onboarding client, which supports Windows
and macOS and has very limited Linux support.

For systems it does not cover, IT's own advice is to register the device manually with the
form for IoT devices. That is not merely a workaround: it means no additional software
runs with administrative rights on your machine, which is a genuine advantage.

The trade-off is that a manual registration expires after
${facts.network.registration_validity} and has to be renewed.

## Documented values

| | |
|---|---|
| Registration form | [IoT device form](${facts.network.registration_form_url}) |
| Valid for | ${facts.network.registration_validity} |
| Wi-Fi network it also covers | `${facts.wifi.thi_ssid}` |
| Onboarding network (not for Linux) | `${facts.wifi.onboard_ssid}` |

## Step 1: collect the MAC addresses

Every port, adapter and docking station has its own MAC address, and **each one needs a
separate registration**. A laptop with a built-in port and a dock is two submissions.

::: os arch

```bash
ip -brief link show
```

:::

::: os debian

```bash
ip -brief link show
```

:::

::: os macos

```bash
networksetup -listallhardwareports
```

:::

Interfaces named `enp…` or `eth…` are wired, `wlp…` or `wlan…` are wireless. If you cannot
tell which entry is the dock, unplug it, run the command again, and compare.

## Step 2: submit the form

Open the [IoT device form](${facts.network.registration_form_url}) once per MAC address.
Each address can be enabled for one area only, so it appears in exactly one submission.

**For a wired port:**

1. *Welche Art von Gerät möchten Sie registrieren?* (What kind of device?) → **Sonstiges
   (auch Linux ARM)**
2. *Benötigen Sie für das Gerät WLAN?* (Does the device need Wi-Fi?) → **Nein**
3. *Gerätename* (Device name) → `<hostname>`
4. *MAC-Adresse* → the wired interface's address
5. *Beschreibung* (Description) → what it is for, e.g. teaching or research access
6. *Betriebssystem inkl. Buildversion* (Operating system and build) → e.g. "Arch Linux
   (rolling release)"
7. *Freischaltung Bereich* (Area to enable) → the network area you need

**For `${facts.wifi.thi_ssid}` Wi-Fi:** the same form, with *Benötigen Sie für das Gerät
WLAN?* set to **Ja** and the MAC address of the wireless interface.

Field labels are quoted in German because that is what the form shows. A translated label
is one you cannot find on screen.

## Step 3: wait

Submitting starts an approval request handled by a person. Progress notifications arrive
by Teams and email.

For `${facts.wifi.thi_ssid}` you receive separate credentials. For Ethernet you get a
general release for campus ports, valid ${facts.network.registration_validity}.

Start this early if you know you will need it. Nothing about it is instant.

## Verify

Plug into a campus port and check that you got an address from the campus network rather
than a self-assigned one:

::: os arch

```bash
ip -brief address show
```

:::

::: os debian

```bash
ip -brief address show
```

:::

::: os macos

```bash
ifconfig en0 | grep 'inet '
```

:::

An address in `169.254.x.x` (or `link/ether` with no `inet` at all) means authentication
did not succeed: the registration is not active yet, or that MAC was never submitted.

## Known quirks

**Still required in some rooms.** Some lecture-hall ports, the D building among them,
authenticate this way rather than through the newer path.

**One MAC, one area.** An address enabled for one network area cannot be submitted again
for another.

**Renewal is on you.** Nothing warns you before the ${facts.network.registration_validity}
expires; it simply stops working. A calendar reminder at eleven months is the practical
answer.

**Docks shared between people are a trap.** The MAC belongs to the dock, not to your
laptop, so a colleague plugging into your registered dock inherits your registration.

**Reference:** [802.1X LAN configuration
(PDF)](https://mythi.de/kcdownload/kc_13/fileid_285/802.1X-Konfiguration-LAN.pdf).
