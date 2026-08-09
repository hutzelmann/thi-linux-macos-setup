---
layout: home
# navbar.css hides the site title here: a landing page is home, so the link
# back home in the corner is the second time in one screen it says where you are.
pageClass: is-landing
title: 'Linux und macOS an der THI: WLAN, VPN, Drucken, Netzlaufwerke'
titleTemplate: false
description: Die dokumentierten Werte für WLAN, VPN, Drucken und Netzlaufwerke unter Linux und macOS an der Technischen Hochschule Ingolstadt. Inoffiziell.
translatedFrom: f63279a410c94a4f9cc4a075aa37d5b3deabcf34

hero:
  # Siehe die englische Seite: die Überschrift steht fest, damit sie ohne CSS
  # lesbar bleibt und den Namen der Hochschule enthält.
  name: 'Linux & macOS'
  text: an der Technischen Hochschule Ingolstadt
  tagline: Wie du Campus-Dienste auf deinem Rechner zum Laufen bringst. Von der Community gepflegt.
  actions:
    - theme: brand
      text: Neu hier? Gerät einrichten
      link: /de/start/new-machine
    - theme: alt
      text: Wie diese Seiten gepflegt werden
      link: /de/about/how-this-works
---

## Alle Einstellungen auf einen Blick

<FactDeck>
<FactCard title="WLAN" link="/de/wifi/">

| | |
|---|---|
| SSID | `${facts.wifi.eduroam_ssid}` |
| Methode | ${facts.wifi.eduroam_eap} / ${facts.wifi.eduroam_phase2} |
| CA-Zertifikat | `${facts.wifi.eduroam_ca}` |
| Server-Domain | `${facts.wifi.eduroam_domain_suffix}` |
| Identität | `<kennung>@${facts.wifi.eduroam_realm}` |

${facts.wifi.thi_ssid} wird anders konfiguriert.

</FactCard>

<FactCard title="VPN" link="/de/vpn/openfortivpn">

| | |
|---|---|
| Gateway | `${facts.vpn.host}` |
| Port | `${facts.vpn.port}` |
| Anmeldung | SSO im Browser |
| CA-Bundle | `${facts.vpn.ca_bundle}` |

Das Gateway liefert sein Zwischenzertifikat nicht mit, deshalb wird das Bundle einmal
von Hand gebaut. Der Schritt steht auf der Seite.

</FactCard>

<FactCard title="Drucken" link="/de/printing/">

| | |
|---|---|
| Druckserver | `${facts.printing.server}` |
| Warteschlange, Beschäftigte | `${facts.printing.queue}` |
| Warteschlange, Studierende | `${facts.printing.queue_students}` |
| Windows-Domäne | `${facts.printing.smb_domain}` |

Ohne Treiber: [${facts.printing.webprint_url}](${facts.printing.webprint_url}) druckt aus
dem Browser, ohne die Optionen zum Lochen und Heften.

</FactCard>

<FactCard title="Netzlaufwerke" link="/de/shares/smb">

| | |
|---|---|
| Home-Verzeichnis | `${facts.shares.home_server}` |
| Gruppenlaufwerke | `${facts.shares.file_server}` |
| Forschungslaufwerke | `${facts.shares.research_server}` |
| Windows-Domäne | `${facts.shares.domain}` |

Nur im Campusnetz oder über VPN.

</FactCard>

<FactCard title="LAN (Kabel)" link="/de/network/ethernet-802-1x">

| | |
|---|---|
| Methode | ${facts.network.wired_eap} / ${facts.network.wired_phase2} |
| Identität | die Kennung, ohne Realm |
| CA-Zertifikat | **nicht dokumentiert** |
| Registrierung gültig | ${facts.network.registration_validity} |

Das offizielle Dokument schaltet die Zertifikatsprüfung ein und nennt keine
Zertifizierungsstelle, deshalb steht hier auch kein Wert. Die Seite sagt, was damit
offen bleibt.

</FactCard>
</FactDeck>
