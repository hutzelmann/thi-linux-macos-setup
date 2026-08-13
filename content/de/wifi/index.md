---
title: eduroam und @thi WLAN unter Linux und macOS
lastChecked:
  arch: 2026-08-13
description: eduroam und @thi unter Linux und macOS einrichten, mit den Zertifikatsprüfungen, die verhindern, dass ein gefälschter Accesspoint das Hochschulpasswort abgreift.
os: [arch, debian, macos]
translatedFrom: 833bc6786e4dead28dcc26d2ce316d52286893ac
---

# WLAN am Campus

Bringt dich ins Netz. Nimm **${facts.wifi.eduroam_ssid}**. Das funktioniert hier und mit
demselben Profil an jeder anderen Hochschule weltweit. Unten stehen zwei Wege: der
eduroam-Konfigurationsassistent, der die Zertifikatseinstellungen für dich einträgt, und
die Konfiguration von Hand für das System, das du oben auf dieser Seite gewählt hast.

Offizielle Dokumentation: [WLAN-Service der THI](${facts.wifi.official_url}).

## Bitte vor jeder Konfiguration von Hand lesen

Beide Campus-Netze authentifizieren dich mit **deiner Hochschulkennung**, demselben
Passwort, das auch Mail, Noten und alle anderen Systeme öffnet. Das Passwort geht an den
Authentifizierungsserver des Accesspoints. Dein Gerät muss also prüfen, ob es wirklich mit
dem echten Server spricht, bevor es das Passwort sendet.

Diese Prüfung besteht aus zwei Einstellungen, und beide sind nötig:

1. **Ein CA-Zertifikat**: welche Zertifizierungsstelle für den Server bürgen darf.
2. **Ein zu prüfender Servername**: für *welchen* Server diese Stelle bürgen darf.

Fehlt der zweite Punkt, wird jeder Server akzeptiert, der ein Zertifikat derselben
öffentlichen Stelle vorweist, und das sind viele. Fehlen beide, wird alles akzeptiert, was
den passenden Netznamen ausstrahlt. In beiden Fällen kann jemand mit einem Laptop im
Hörsaal dein Passwort einsammeln. Das ist kein theoretischer Fall, sondern der
Standardangriff auf 802.1X-Netze, und von Hand geschriebene Konfigurationen lassen sehr
häufig eine der beiden Einstellungen weg.

Das [Konfigurationswerkzeug](${facts.wifi.cat_url}) macht das prinzipbedingt richtig,
deshalb ist es unten der empfohlene Weg.

## Dokumentierte Werte

| | eduroam | @thi |
|---|---|---|
| Netzname | `${facts.wifi.eduroam_ssid}` | `${facts.wifi.thi_ssid}` |
| Methode | ${facts.wifi.eduroam_eap} | ${facts.wifi.thi_eap} |
| Innere Methode | ${facts.wifi.eduroam_phase2} | ${facts.wifi.thi_phase2} |
| CA-Zertifikat | ${facts.wifi.eduroam_ca} | ${facts.wifi.thi_ca} |
| Servername muss enden auf | `${facts.wifi.eduroam_domain_suffix}` | `${facts.wifi.thi_domain_suffix}` |
| Identität | `<kennung>@${facts.wifi.eduroam_realm}` | `<kennung>` |
| Außerhalb des Campus nutzbar | ja, an jedem eduroam-Standort | nein |
| Geräteregistrierung nötig | nein | ja |

Die CA ist auf allen drei Systemen im Standard-Zertifikatspaket enthalten, es gibt nichts
herunterzuladen. Wo dein System sie ablegt:

::: os arch

`${facts.wifi.eduroam_ca_path_arch}`

:::

::: os debian

`${facts.wifi.eduroam_ca_path_debian}`

:::

::: os macos

Im Systemschlüsselbund, unter dem Namen des Zertifikats statt unter einem Pfad. Ein
Profil verweist über den Namen darauf, es gibt also keine Datei zum Angeben.

:::

::: warning Ältere Notizen nennen die falsche CA
Notizen von vor 2026 nennen ein USERTrust-Zertifikat. Die THI hat auf
${facts.wifi.eduroam_ca} gewechselt. Ein Profil, das noch auf die alte Stelle zeigt,
verbindet sich entweder nicht mehr oder, schlimmer, funktioniert weiter und prüft dabei
nichts.
:::

## eduroam, der einfache Weg

Das [eduroam Configuration Assistant Tool](${facts.wifi.cat_url}) erzeugt ein Profil, in
dem CA und Servername bereits eingetragen sind. Technische Hochschule Ingolstadt wählen,
Installer für das eigene System herunterladen, ausführen, dann
`<kennung>@${facts.wifi.eduroam_realm}` und Passwort eingeben.

::: os arch

Der CAT-Installer ist ein Python-Skript. Wer es nicht direkt auf dem eigenen System
ausführen möchte, erzeugt das Profil in einem Container und kopiert die fertige
Konfiguration heraus:

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

Der CAT-Installer ist ein Python-Skript und läuft direkt:

```bash
sudo apt install python3 python3-dbus
python3 eduroam-linux-*.py
```

:::

::: os macos

CAT liefert ein `.mobileconfig`-Profil. Herunterladen, öffnen und unter
**Systemeinstellungen → Allgemein → VPN & Geräteverwaltung** bestätigen. macOS übernimmt
die Zertifikatsprüfung dann selbst.

:::

## eduroam von Hand

Nur, wenn es einen Grund gibt, den Installer zu meiden. Beide Zertifikatseinstellungen
unten sind zwingend; ein Profil ohne sie ist genau der Fall, der oben beschrieben ist.

::: os arch

```bash
nmcli connection add type wifi con-name eduroam ssid ${facts.wifi.eduroam_ssid} \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "<kennung>@${facts.wifi.eduroam_realm}" \
  802-1x.ca-cert "${facts.wifi.eduroam_ca_path_arch}" \
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
  802-1x.ca-cert "${facts.wifi.eduroam_ca_path_debian}" \
  802-1x.domain-suffix-match "${facts.wifi.eduroam_domain_suffix}"
```

:::

::: os macos

macOS bietet die Prüfung des Servernamens im WLAN-Dialog nicht an. Nutze das CAT-Profil.
Eine Konfiguration von Hand lässt sich über die Oberfläche allein nicht sicher machen.

:::

## @thi

Ein reines Campus-Netz, das ${facts.wifi.thi_eap} statt ${facts.wifi.eduroam_eap}
verwendet. Das Gerät muss vorher registriert sein, und du bekommst dafür eigene
Zugangsdaten. Der Ablauf steht unter
[Ethernet: 802.1X und Geräteregistrierung](/de/network/ethernet-802-1x); dasselbe Formular
gilt auch für WLAN.

Gegenüber ${facts.wifi.eduroam_ssid} gibt es kaum einen Grund dafür, außer etwas verlangt
es ausdrücklich. eduroam braucht keine Registrierung und funktioniert überall.

Es gelten dieselben zwei Zertifikatseinstellungen, mit `802-1x.eap ttls`.

## Prüfen

<ScriptDownload file="wifi-verify.sh" does="Meldet, ob deine Profile den Anmeldeserver wirklich prüfen" />

Wichtig an der Ausgabe ist nicht, ob du verbunden bist, sondern ob das Profil den Server
prüft. Von Hand:

::: os arch

```bash
nmcli -f 802-1x.ca-cert,802-1x.domain-suffix-match connection show eduroam
```

Beide Felder müssen gefüllt sein, und das zweite muss
`${facts.wifi.eduroam_domain_suffix}` lauten. Ein leeres `domain-suffix-match` ist das mit
Abstand häufigste Problem, und es ist unsichtbar, weil das Netz so oder so funktioniert.

:::

::: os debian

```bash
nmcli -f 802-1x.ca-cert,802-1x.domain-suffix-match connection show eduroam
```

Beide Felder müssen gefüllt sein, und das zweite muss
`${facts.wifi.eduroam_domain_suffix}` lauten. Ein leeres `domain-suffix-match` ist das mit
Abstand häufigste Problem, und es ist unsichtbar, weil das Netz so oder so funktioniert.

:::

::: os macos

```bash
security find-certificate -c "${facts.wifi.eduroam_ca}" /Library/Keychains/System.keychain
```

Das sagt, dass die Stelle vorhanden ist, nicht dass dein Profil einen Servernamen dagegen
prüft. macOS hält das im Profil, die Frage lautet also, ob das Profil vom
Konfigurationsassistenten stammt: **Systemeinstellungen → Allgemein → VPN &
Geräteverwaltung**.

:::

## Bekannte Eigenheiten

**`${facts.wifi.onboard_ssid}` ist kein Netz zum Bleiben.** Es existiert für den
offiziellen Onboarding-Client.

::: os arch

Dieser Client unterstützt Windows und macOS, Linux nur sehr eingeschränkt. Registriere das
Gerät stattdessen: [Ethernet: 802.1X und MAC-Registrierung](/de/network/ethernet-802-1x).

:::

::: os debian

Dieser Client unterstützt Windows und macOS, Linux nur sehr eingeschränkt. Registriere das
Gerät stattdessen: [Ethernet: 802.1X und MAC-Registrierung](/de/network/ethernet-802-1x).

:::

::: os macos

Dieser Client deckt macOS ab, dieses Netz ist also der Weg, den er nimmt. Die
Registrierung von Hand funktioniert ebenfalls:
[Ethernet: 802.1X und MAC-Registrierung](/de/network/ethernet-802-1x).

:::

**Der Wechsel zwischen Gebäuden kann die Sitzung abreißen lassen**, abhängig vom Treiber.
Das ist meist eine Sache von `wpa_supplicant` und nicht campusspezifisch.

**Die Identität hat einen Realm, der Benutzername nicht.** eduroam möchte
`<kennung>@${facts.wifi.eduroam_realm}`, @thi die reine Kennung. Verwechselt man das, gibt
es einen Anmeldefehler ohne brauchbare Meldung.
