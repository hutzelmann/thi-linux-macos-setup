---
title: 'Ethernet on campus: 802.1X and MAC registration'
lastChecked:
  arch: 2026-08-13
description: 'Get a Linux or Mac device onto a campus Ethernet port: 802.1X login, or registering the adapter by MAC address, and how to tell which one a port wants.'
os: [arch, debian, macos]
---

# Ethernet on campus

Gets a Linux or Mac device onto a campus Ethernet port, and onto the
`${facts.wifi.thi_ssid}` network. Two different things can happen when you plug in, and
the port decides which:

- **802.1X port authentication.** The port asks your machine to log in, and you answer
  with your campus login. Nothing is registered in advance. This is the newer path and
  the one most ports now take.
- **MAC address registration.** The port compares your adapter's hardware address against
  a list, and lets it through if the address was registered. Some lecture-hall ports, the
  D building among them, still work this way. The same registration also covers the
  `${facts.wifi.thi_ssid}` Wi-Fi network.

Official documentation: [MyTHI: network and Wi-Fi on campus](${facts.network.official_url})
(login required).

::: tip You may not need either
[eduroam](/en/wifi/) needs no registration, works in every building, and works at other
universities too. Reach for a wired port when you specifically need one.
:::

## Which one does this port want

Plug in and watch. If a password prompt appears, or your machine reports that
authentication is required, the port speaks 802.1X: use the first path below. If nothing
is asked and you simply never get an address, the port is checking hardware addresses:
use the second.

Trying 802.1X first costs nothing. A port that does not ask never sees the credential.

---

## Path 1: 802.1X port authentication

### Documented values

| Item | Value |
|---|---|
| Method | ${facts.network.wired_eap} |
| Inner method | ${facts.network.wired_phase2} |
| Identity | `<kennung>`, with no realm and no domain |
| Authentication mode | user, not machine |
| CA certificate | ${facts.network.wired_ca} |
| Server name to match | `${facts.network.wired_domain_suffix}` |
| Authentication server | `${facts.network.wired_server_name}` |

Both certificate settings are required. Your campus login is the password that also
reaches your mail and everything else, and a profile that does not check the
authentication server's certificate hands it to anything willing to ask.
[Wi-Fi on campus](/en/wifi/) explains that at length, including why naming a CA without
also matching a server name only narrows the attack rather than closing it.

The official configuration guide ticks *Serverzertifikat überprüfen* (check the server
certificate) and then leaves the trusted authority unselected and *Verbindung mit
folgenden Servern herstellen* (connect to these servers) empty, so the two values above
do not come from it. They were read off a campus port on 2026-08-13 and confirmed out of
band before being written down. The wired port and ${facts.wifi.eduroam_ssid} presented
the same certificate chain that day, fingerprints included, so the wireless CA in
`facts/wifi.yaml` and the wired one here name one server.

### The click path

::: os arch

**GNOME:** Settings → Network → the wired connection's gear icon → **Security** tab →
switch **802.1X Security** on. Authentication `Protected EAP (PEAP)`, inner
authentication `${facts.network.wired_phase2}`, username `<kennung>`, password your campus password.

**KDE:** System Settings → Wi-Fi & Networking → the wired connection → **802.1x
Security**, same four values.

Then the two certificate settings: **CA certificate** →
`${facts.wifi.eduroam_ca_path_arch}`, which is ${facts.network.wired_ca} as the
`ca-certificates` package installs it, and **Domain** (GNOME) or **Domain suffix match**
(KDE) → `${facts.network.wired_domain_suffix}`.

Leave anonymous identity empty.

:::

::: os debian

**GNOME:** Settings → Network → the wired connection's gear icon → **Security** tab →
switch **802.1X Security** on. Authentication `Protected EAP (PEAP)`, inner
authentication `${facts.network.wired_phase2}`, username `<kennung>`, password your campus password.

**KDE:** System Settings → Wi-Fi & Networking → the wired connection → **802.1x
Security**, same four values.

Then the two certificate settings: **CA certificate** →
`${facts.wifi.eduroam_ca_path_debian}`, which is ${facts.network.wired_ca} as the
`ca-certificates` package installs it, and **Domain** (GNOME) or **Domain suffix match**
(KDE) → `${facts.network.wired_domain_suffix}`.

Leave anonymous identity empty.

:::

::: os macos

macOS asks by itself. Plug into a port that speaks 802.1X and a sign-in prompt appears
for the Ethernet service; enter `<kennung>` and your campus password.

macOS then shows the authentication server's certificate and asks whether to trust it.
That dialogue is the only server check you get here, and it is a one-time human decision
rather than a setting: the name to expect is `${facts.network.wired_server_name}`, issued
under ${facts.network.wired_ca}. Read it before you accept it, because accepting stores
it for good.

To configure it before plugging in: System Settings → Network → Ethernet → Details →
**802.1X**.

:::

### The terminal fast path

::: os arch

```bash
nmcli connection add type ethernet con-name "THI 802.1X" ifname enp0s31f6 \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "<kennung>" \
  802-1x.ca-cert "${facts.wifi.eduroam_ca_path_arch}" \
  802-1x.domain-suffix-match "${facts.network.wired_domain_suffix}" \
  802-1x.password-flags 2
nmcli connection up "THI 802.1X" --ask
```

`ifname` is the wired interface from `ip -brief link show`. `password-flags 2` asks for
the password at connect time instead of storing it; drop it and add
`802-1x.password "<password>"` if you would rather keep it in the keyring.

The profile name is yours to choose. It is a local label and campus systems never see it.

:::

::: os debian

```bash
nmcli connection add type ethernet con-name "THI 802.1X" ifname enp0s31f6 \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "<kennung>" \
  802-1x.ca-cert "${facts.wifi.eduroam_ca_path_debian}" \
  802-1x.domain-suffix-match "${facts.network.wired_domain_suffix}" \
  802-1x.password-flags 2
nmcli connection up "THI 802.1X" --ask
```

`ifname` is the wired interface from `ip -brief link show`. `password-flags 2` asks for
the password at connect time instead of storing it; drop it and add
`802-1x.password "<password>"` if you would rather keep it in the keyring.

The profile name is yours to choose. It is a local label and campus systems never see it.

:::

::: os macos

`networksetup` cannot create an 802.1X profile. Use the dialogue above, or install a
`.mobileconfig` profile if your department distributes one.

:::

### Verify

<ScriptDownload file="network-verify.sh" does="Reports the profile, the address the port handed out, and the hardware addresses that would each need their own registration" />

It covers both paths on this page, and `--evidence` writes down everything it saw. A
wired port is the one thing here you have to be standing next to, so recording the run is
worth more than reading it.

::: os arch

```bash
nmcli -f GENERAL.STATE,IP4.ADDRESS device show enp0s31f6
nmcli -f 802-1x.ca-cert,802-1x.domain-suffix-match connection show "THI 802.1X"
```

:::

::: os debian

```bash
nmcli -f GENERAL.STATE,IP4.ADDRESS device show enp0s31f6
nmcli -f 802-1x.ca-cert,802-1x.domain-suffix-match connection show "THI 802.1X"
```

:::

::: os macos

```bash
ifconfig en0 | grep 'inet '
```

:::

An address from the campus network means the login was accepted. An address in
`169.254.x.x`, or none at all, means it was not, or that this port wants a registered MAC
address instead.

The second command prints the two certificate fields. Both must be non-empty, and the
suffix must read `${facts.network.wired_domain_suffix}`. A profile built by following
only the official guide has neither, and it authenticates exactly as well as one that
does, which is why this is worth looking at rather than assuming.

---

## Path 2: registration by MAC address

### Why registration rather than the official client

Where a port checks hardware addresses, authentication is based on a whitelist. The
documented route to get onto that list is a dedicated onboarding network and the vendor's
onboarding client.

::: os arch

That client supports Windows and macOS, and its Linux support is very limited. For the
systems it does not cover, IT's own advice is to register the device manually with the
form for IoT devices. That is not merely a workaround: it means no additional software
runs with administrative rights on your machine, which is a genuine advantage.

:::

::: os debian

That client supports Windows and macOS, and its Linux support is very limited. For the
systems it does not cover, IT's own advice is to register the device manually with the
form for IoT devices. That is not merely a workaround: it means no additional software
runs with administrative rights on your machine, which is a genuine advantage.

:::

::: os macos

That client covers macOS, so it is available to you. Registering the device manually with
the form for IoT devices is the alternative, and it is the route this page describes: no
additional software runs with administrative rights on your machine, which is a genuine
advantage.

:::

The trade-off is that a manual registration expires after
${facts.network.registration_validity} and has to be renewed.

### Documented values

| Item | Value |
|---|---|
| Registration form | [IoT device form](${facts.network.registration_form_url}) |
| Valid for | ${facts.network.registration_validity} |
| Wi-Fi network it also covers | `${facts.wifi.thi_ssid}` |
| Onboarding network, for the official client | `${facts.wifi.onboard_ssid}` |

### Step 1: collect the MAC addresses

Every port, adapter and docking station has its own MAC address, and **each one needs a
separate registration**. A laptop with a built-in port and a dock is two submissions.

::: os arch

```bash
ip -brief link show
```

Interfaces named `enp…` or `eth…` are wired, `wlp…` or `wlan…` are wireless.

:::

::: os debian

```bash
ip -brief link show
```

Interfaces named `enp…` or `eth…` are wired, `wlp…` or `wlan…` are wireless.

:::

::: os macos

```bash
networksetup -listallhardwareports
```

Each block names a hardware port and its address. **Ethernet** and **Thunderbolt
Ethernet** are the wired ones; **Wi-Fi** is the wireless one.

:::

If you cannot tell which entry is the dock, unplug it, run the command again, and compare.

### Step 2: submit the form

Open the [IoT device form](${facts.network.registration_form_url}) once per MAC address.
Each address can be enabled for one area only, so it appears in exactly one submission.

**For a wired port:**

1. *Welche Art von Gerät möchten Sie registrieren?* (What kind of device?) → **Sonstiges
   (auch Linux ARM)**
2. *Benötigen Sie für das Gerät WLAN?* (Does the device need Wi-Fi?) → **Nein**
3. *Gerätename* (Device name) → `<hostname>`
4. *MAC-Adresse* → the wired interface's address
5. *Beschreibung* (Description) → what it is for, e.g. teaching or research access
6. *Betriebssystem inkl. Buildversion* (Operating system and build) → the system you run
   and its version, as you would name it yourself
7. *Freischaltung Bereich* (Area to enable) → the network area you need

**For `${facts.wifi.thi_ssid}` Wi-Fi:** the same form, with *Benötigen Sie für das Gerät
WLAN?* set to **Ja** and the MAC address of the wireless interface.

Field labels are quoted in German because that is what the form shows. A translated label
is one you cannot find on screen.

### Step 3: wait

Submitting starts an approval request handled by a person. Progress notifications arrive
by Teams and email.

For `${facts.wifi.thi_ssid}` you receive separate credentials. For Ethernet you get a
general release for campus ports, valid ${facts.network.registration_validity}.

Start this early if you know you will need it. Nothing about it is instant.

### Verify

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

An address in `169.254.x.x`, or no address at all, means authentication did not succeed:
the registration is not active yet, or that MAC was never submitted.

---

## Known quirks

**The identity carries no realm.** Wired 802.1X and `${facts.wifi.thi_ssid}` want the bare
`<kennung>`; eduroam wants `<kennung>@${facts.wifi.eduroam_realm}`. Mixing them up gives
an authentication failure with no useful message. Leave the Windows-style domain field
empty as well.

**User, not machine.** The official configuration authenticates the person, so the port
comes up after you log in rather than at boot. A machine expected to be reachable while
nobody is signed in is a different setup, and this page does not document one.

**One MAC, one area.** An address registered for one network area cannot be submitted
again for another.

**Renewal is on you.** Nothing warns you before the ${facts.network.registration_validity}
expires; it simply stops working. A calendar reminder at eleven months is the practical
answer.

**Docks shared between people are a trap, in opposite directions.** Under registration the
MAC belongs to the dock, so a colleague plugging into your registered dock inherits your
registration. Under 802.1X the credential is yours and travels with the machine, so a
shared dock is not the problem; the port asking a second device on the same dock is.

**Reference:** [802.1X LAN configuration (PDF)](${facts.network.wired_official_pdf}), a
Windows click path, useful here for the values rather than the steps.
