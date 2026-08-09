---
layout: home
# navbar.css hides the site title here: a landing page is home, so the link
# back home in the corner is the second time in one screen it says where you are.
pageClass: is-landing
title: 'Linux and macOS at THI: Wi-Fi, VPN, printing, shares'
titleTemplate: false
description: The documented values for campus Wi-Fi, VPN, printing and network shares on Linux and macOS at Technische Hochschule Ingolstadt, in one place. Unofficial.

hero:
  # The headline is one fixed string. The three OS variants used to stand here,
  # and since all of them stay in the DOM the h1 read "Arch LinuxDebian and
  # UbuntumacOS @ THI" to anything that does not apply CSS, with the
  # university's name nowhere in it.
  name: 'Linux & macOS'
  text: at Technische Hochschule Ingolstadt
  tagline: How to get campus systems working on your machine. Community-maintained.
  actions:
    - theme: brand
      text: New here? Set up a new machine
      link: /en/start/new-machine
    - theme: alt
      text: How these pages are kept
      link: /en/about/how-this-works
---

## Every setting at a glance

<FactDeck>
<FactCard title="Wi-Fi" link="/en/wifi/">

| | |
|---|---|
| SSID | `${facts.wifi.eduroam_ssid}` |
| Method | ${facts.wifi.eduroam_eap} / ${facts.wifi.eduroam_phase2} |
| CA certificate | `${facts.wifi.eduroam_ca}` |
| Server domain | `${facts.wifi.eduroam_domain_suffix}` |
| Identity | `<kennung>@${facts.wifi.eduroam_realm}` |

${facts.wifi.thi_ssid} is configured differently.

</FactCard>

<FactCard title="VPN" link="/en/vpn/openfortivpn">

| | |
|---|---|
| Gateway | `${facts.vpn.host}` |
| Port | `${facts.vpn.port}` |
| Sign-in | SSO in the browser |
| CA bundle | `${facts.vpn.ca_bundle}` |

The gateway does not send its intermediate certificate, so the bundle is built once by
hand. The page has that step.

</FactCard>

<FactCard title="Printing" link="/en/printing/">

| | |
|---|---|
| Print server | `${facts.printing.server}` |
| Queue, staff | `${facts.printing.queue}` |
| Queue, students | `${facts.printing.queue_students}` |
| Windows domain | `${facts.printing.smb_domain}` |

No driver installed: [${facts.printing.webprint_url}](${facts.printing.webprint_url})
prints from the browser, without the finishing options.

</FactCard>

<FactCard title="Network shares" link="/en/shares/smb">

| | |
|---|---|
| Home directory | `${facts.shares.home_server}` |
| Group shares | `${facts.shares.file_server}` |
| Research shares | `${facts.shares.research_server}` |
| Windows domain | `${facts.shares.domain}` |

Campus network or VPN only.

</FactCard>

<FactCard title="Wired Ethernet" link="/en/network/ethernet-802-1x">

| | |
|---|---|
| Method | ${facts.network.wired_eap} / ${facts.network.wired_phase2} |
| Identity | the campus login, no realm |
| CA certificate | **not documented** |
| Registration valid | ${facts.network.registration_validity} |

The official document turns certificate checking on and names no authority, so this
project records no value either. The page says what that leaves open.

</FactCard>
</FactDeck>
