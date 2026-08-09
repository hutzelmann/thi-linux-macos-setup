---
title: eduroam and @thi Wi-Fi on Linux and macOS
description: Connect to eduroam and @thi from Linux and macOS, with the certificate checks that stop a fake access point from stealing your campus password.
os: [arch, debian, macos]
---

# Wi-Fi on campus

Gets you online. Use **${facts.wifi.eduroam_ssid}**. It works here and at every other
university in the world with the same profile. The steps below cover the eduroam CAT
installer, NetworkManager (`nmcli`) and `wpa_supplicant` on Linux, and a configuration
profile on macOS.

Official documentation: [THI Wi-Fi service](${facts.wifi.official_url}).

## Read this before configuring anything by hand

Both campus networks authenticate you with **your campus login**, the same password
that reaches your mail, your grades and every other system. The password is sent to the
access point's authentication server, so your device must confirm it is talking to the
real one before sending it.

That confirmation is two settings, and both are required:

1. **A CA certificate**: which authority is allowed to vouch for the server.
2. **A server name to match**: which server that authority is allowed to vouch *for*.

With only the first, any server holding a certificate from the same public authority is
accepted, and that is a large set. With neither, anything broadcasting the right network
name is accepted. In both cases someone with a laptop in a lecture hall can collect your
password. This is not theoretical. It is the standard attack against 802.1X networks,
and hand-written configurations very often omit one or both.

The [configuration assistant](${facts.wifi.cat_url}) gets this right by construction,
which is why it is the recommended route below.

## Documented values

| | eduroam | @thi |
|---|---|---|
| Network name | `${facts.wifi.eduroam_ssid}` | `${facts.wifi.thi_ssid}` |
| Method | ${facts.wifi.eduroam_eap} | ${facts.wifi.thi_eap} |
| Inner method | ${facts.wifi.eduroam_phase2} | ${facts.wifi.thi_phase2} |
| CA certificate | ${facts.wifi.eduroam_ca} | ${facts.wifi.thi_ca} |
| Server name must end in | `${facts.wifi.eduroam_domain_suffix}` | `${facts.wifi.thi_domain_suffix}` |
| Identity | `<kennung>@${facts.wifi.eduroam_realm}` | `<kennung>` |
| Works off campus | yes, at any eduroam site | no |
| Device registration needed | no | yes |

The CA ships with the standard certificate bundle on all three systems, so there is
nothing to download. On Linux it is at `${facts.wifi.eduroam_ca_path}`.

::: warning Older notes name the wrong CA
Notes written before 2026 name a USERTrust certificate. THI has moved to
${facts.wifi.eduroam_ca}. A profile still pointing at the old authority will either stop
connecting or, worse, keep working while validating nothing.
:::

## eduroam, the easy way

The [eduroam Configuration Assistant Tool](${facts.wifi.cat_url}) generates a profile
with the CA and server name already filled in. Choose Technische Hochschule Ingolstadt,
download the installer for your system, run it, enter `<kennung>@${facts.wifi.eduroam_realm}`
and your password.

::: os arch

The CAT installer is a Python script. If you would rather not run it directly on your
system, generate the profile inside a container and copy out the resulting config:

```bash
docker run -it --rm debian:stable
apt update && apt install -y curl python3
curl "${facts.wifi.cat_url}user/API.php?action=downloadInstaller&lang=en&profile=${facts.wifi.cat_profile}&device=linux&generatedfor=user&openroaming=0" > script.py
mkdir -p /root/.config/cat_installer
python3 script.py
cat /root/.config/cat_installer/cat_installer.conf
```

:::

::: os debian

The CAT installer is a Python script and runs directly:

```bash
sudo apt install python3 python3-dbus
python3 eduroam-linux-*.py
```

:::

::: os macos

CAT provides a `.mobileconfig` profile. Download it, open it, and approve it under
**System Settings → General → VPN & Device Management**. macOS then handles the
certificate check itself.

:::

## eduroam by hand

Only if you have a reason to avoid the installer. Both certificate settings below are
mandatory; a profile without them is the failure described at the top of this page.

::: os arch

```bash
nmcli connection add type wifi con-name eduroam ssid ${facts.wifi.eduroam_ssid} \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "<kennung>@${facts.wifi.eduroam_realm}" \
  802-1x.ca-cert "${facts.wifi.eduroam_ca_path}" \
  802-1x.domain-suffix-match "${facts.wifi.eduroam_domain_suffix}"
```

:::

::: os debian

```bash
nmcli connection add type wifi con-name eduroam ssid ${facts.wifi.eduroam_ssid} \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "<kennung>@${facts.wifi.eduroam_realm}" \
  802-1x.ca-cert "/etc/ssl/certs/HARICA_TLS_RSA_Root_CA_2021.pem" \
  802-1x.domain-suffix-match "${facts.wifi.eduroam_domain_suffix}"
```

:::

::: os macos

macOS does not expose server-name matching in the Wi-Fi dialogue. Use the CAT profile.
Hand configuration on macOS cannot be made safe through the UI alone.

:::

## @thi

A campus-only network using ${facts.wifi.thi_eap} instead of
${facts.wifi.eduroam_eap}. It needs the device to be registered first, and you receive
separate credentials for it. See
[Ethernet: 802.1X and device registration](/en/network/ethernet-802-1x) for the
registration process; the same form covers Wi-Fi.

There is little reason to prefer it over ${facts.wifi.eduroam_ssid} unless something
specifically requires it. eduroam needs no registration and works everywhere.

The same two certificate settings apply, with `802-1x.eap ttls`.

## Verify

<ScriptDownload file="wifi-verify.sh" does="Reports whether your profiles actually validate the authentication server" />

The important part of the output is not whether you are connected. It is whether the
profile validates the server. By hand:

::: os arch

```bash
nmcli -f 802-1x.ca-cert,802-1x.domain-suffix-match connection show eduroam
```

:::

::: os debian

```bash
nmcli -f 802-1x.ca-cert,802-1x.domain-suffix-match connection show eduroam
```

:::

::: os macos

```bash
security find-certificate -c "${facts.wifi.eduroam_ca}" /Library/Keychains/System.keychain
```

:::

Both fields must be non-empty. An empty `domain-suffix-match` is the single most common
problem, and it is invisible: the network works perfectly either way.

## Known quirks

**`${facts.wifi.onboard_ssid}` is not a network you stay on.** It exists for the official onboarding
client, which supports Windows and macOS. On Linux, register the device instead.

**Roaming between buildings can drop the session** on some drivers. Usually a
`wpa_supplicant` matter rather than anything campus-specific.

**The identity has a realm, the username does not.** eduroam wants
`<kennung>@${facts.wifi.eduroam_realm}`; @thi wants the bare login. Mixing them up gives
an authentication failure with no useful message.

