---
title: 'Ethernet on campus: 802.1X and MAC registration'
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
| CA certificate | not documented, see below |
| Server name to match | not documented, see below |

::: warning The two certificate settings are missing from the documented configuration
Both campus paths carry your campus login, the password that also reaches your mail and
everything else. [Wi-Fi on campus](/en/wifi/) explains at length why a profile that does
not check the authentication server's certificate hands that password to anything willing
to ask for it, and why naming a CA without also matching a server name only narrows the
attack rather than closing it.

The official document ticks *Serverzertifikat überprüfen* (check the server certificate)
and then leaves the trusted authority unselected and *Verbindung mit folgenden Servern
herstellen* (connect to these servers) empty. A working profile inspected on campus
carried neither value either. So this page cannot tell you what to fill in, and will not
guess: on wired ports the certificate is checked against nothing in particular.

The wireless networks match `${facts.wifi.eduroam_domain_suffix}` against
${facts.wifi.eduroam_ca}. Whether the wired ports use the same authentication server is
exactly the question, and an assumption here would be the kind of plausible-looking
value that is worse than an admitted gap. If you confirm it out of band, that is worth an
issue.
:::

### The click path

::: os arch

**GNOME:** Settings → Network → the wired connection's gear icon → **Security** tab →
switch **802.1X Security** on. Authentication `Protected EAP (PEAP)`, inner
authentication `${facts.network.wired_phase2}`, username `<kennung>`, password your campus password.

**KDE:** System Settings → Wi-Fi & Networking → the wired connection → **802.1x
Security**, same four values.

Leave anonymous identity empty. The CA certificate field is where the missing value
above would go.

:::

::: os debian

**GNOME:** Settings → Network → the wired connection's gear icon → **Security** tab →
switch **802.1X Security** on. Authentication `Protected EAP (PEAP)`, inner
authentication `${facts.network.wired_phase2}`, username `<kennung>`, password your campus password.

**KDE:** System Settings → Wi-Fi & Networking → the wired connection → **802.1x
Security**, same four values.

Leave anonymous identity empty. The CA certificate field is where the missing value
above would go.

:::

::: os macos

macOS asks by itself. Plug into a port that speaks 802.1X and a sign-in prompt appears
for the Ethernet service; enter `<kennung>` and your campus password.

macOS then shows the authentication server's certificate and asks whether to trust it.
That dialogue is the only server check you get here, and it is a one-time human decision
rather than a setting: read the certificate's name before you accept it, because
accepting stores it for good.

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

The second command prints the two certificate fields. Both are empty on a profile built
from the documented values, which is the gap described above rather than a mistake you
made.

---

## Path 2: registration by MAC address

### Why registration rather than the official client

Where a port checks hardware addresses, authentication is based on a whitelist. The
documented route to get onto that list is a dedicated onboarding network and the vendor's
onboarding client, which supports Windows and macOS and has very limited Linux support.

For systems it does not cover, IT's own advice is to register the device manually with the
form for IoT devices. That is not merely a workaround: it means no additional software
runs with administrative rights on your machine, which is a genuine advantage.

The trade-off is that a manual registration expires after
${facts.network.registration_validity} and has to be renewed.

### Documented values

| Item | Value |
|---|---|
| Registration form | [IoT device form](${facts.network.registration_form_url}) |
| Valid for | ${facts.network.registration_validity} |
| Wi-Fi network it also covers | `${facts.wifi.thi_ssid}` |
| Onboarding network (not for Linux) | `${facts.wifi.onboard_ssid}` |

### Step 1: collect the MAC addresses

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
6. *Betriebssystem inkl. Buildversion* (Operating system and build) → e.g. "Arch Linux
   (rolling release)"
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

An address in `169.254.x.x` (or `link/ether` with no `inet` at all) means authentication
did not succeed: the registration is not active yet, or that MAC was never submitted.

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
