---
title: Wired ports and device registration
description: Registering a Linux device for campus Ethernet and the @thi network by MAC address, when the official onboarding client will not run.
status: imported
os: [arch, debian, macos]
---

# Wired ports and device registration

Gets a Linux or Mac device onto campus Ethernet ports, and onto the
`${facts.wifi.thi_ssid}` network. Both use the same registration.

Official documentation: [network sign-on](${facts.network.kb_url}) ·
[MyTHI: network and Wi-Fi on campus](${facts.network.official_url}) (login required).

## Why registration rather than the official client

Wired authentication is based on a whitelist of MAC addresses. The documented route is a
dedicated onboarding network and the vendor's onboarding client, which supports Windows
and macOS and has very limited Linux support.

For systems it does not cover, IT's own advice is to register the device manually using
the form for IoT devices. That has a real advantage beyond convenience: no additional
software runs with administrative rights on the machine.

The trade-off is that a manual registration is valid for
${facts.network.registration_validity} and has to be renewed.

## Collect the MAC addresses first

Every port, adapter and docking station has its own MAC address, and each one needs a
separate registration.

```bash
ip link show
```

If you cannot tell which is which, plug and unplug each device and compare the list.

## Submit the form

Open the [IoT device form](${facts.network.registration_form_url}) once per MAC address —
each address can be enabled for one area only.

**For a wired port:**

1. *Welche Art von Gerät möchten Sie registrieren?* (What kind of device?) → **Sonstiges
   (auch Linux ARM)**
2. *Benötigen Sie für das Gerät WLAN?* (Does the device need Wi-Fi?) → **Nein**
3. *Gerätename* (Device name) → `<hostname>`
4. *MAC-Adresse* → the Ethernet interface's address, e.g. from `enp…`
5. *Beschreibung* (Description) → what it is for, e.g. teaching or research access
6. *Betriebssystem inkl. Buildversion* (Operating system and build) → e.g. "Arch Linux
   (rolling release)"
7. *Freischaltung Bereich* (Area to enable) → the network area you need

**For `${facts.wifi.thi_ssid}` Wi-Fi:** the same form, with *Benötigen Sie für das Gerät
WLAN?* set to **Ja** and the MAC address of the wireless interface.

Field labels are quoted in German because that is what the form shows.

## After submitting

The form starts an approval request. Progress notifications arrive by Teams and email.

For `${facts.wifi.thi_ssid}` you receive separate credentials. For Ethernet you get a
general release for campus ports, valid ${facts.network.registration_validity}.

## Known quirks

**Still required in some rooms.** Some lecture-hall ports — the D building among them —
still authenticate this way rather than through the newer path.

**One MAC, one area.** An address enabled for one network area cannot be submitted again
for another.

**Reference:** [802.1X LAN configuration
(PDF)](https://mythi.de/kcdownload/kc_13/fileid_285/802.1X-Konfiguration-LAN.pdf).

---

::: info Imported notes
This page came from personal notes and has not been restructured or re-checked. The
steps were accurate when written. If you go through the process, a
[check record](https://github.com/hutzelmann/thi-linux-macos-setup/issues/new?template=check-record.yml)
saying what you saw is the most useful thing you can contribute.
:::
