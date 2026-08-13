---
title: 'Ethernet am Campus: 802.1X und MAC-Registrierung'
lastChecked:
  arch: 2026-08-13
description: 'Ein Linux- oder Mac-Gerät an eine Netzwerkdose am Campus bringen: Anmeldung per 802.1X, oder den Adapter per MAC-Adresse registrieren, und wie du erkennst, was eine Dose will.'
os: [arch, debian, macos]
translatedFrom: 60c3ff363646910d188a8e4258955136ecfbf6b2
---

# Ethernet am Campus

Bringt ein Linux- oder Mac-Gerät an eine Netzwerkdose am Campus und ins Netz
`${facts.wifi.thi_ssid}`. Beim Einstecken können zwei verschiedene Dinge passieren, und
die Dose entscheidet, welches:

- **Portauthentifizierung per 802.1X.** Die Dose fordert deinen Rechner zur Anmeldung auf,
  und du antwortest mit deiner Hochschulkennung. Vorher wird nichts registriert. Das ist
  der neuere Weg und der, den die meisten Dosen inzwischen gehen.
- **Registrierung der MAC-Adresse.** Die Dose vergleicht die Hardwareadresse deines
  Adapters mit einer Liste und lässt ihn durch, wenn die Adresse registriert wurde. Manche
  Hörsaaldosen, darunter im Gebäude D, arbeiten weiterhin so. Dieselbe Registrierung deckt
  auch das WLAN `${facts.wifi.thi_ssid}` ab.

Offizielle Dokumentation: [MyTHI: Netz und WLAN am Campus](${facts.network.official_url})
(Anmeldung nötig).

::: tip Vielleicht brauchst du keines von beiden
[eduroam](/de/wifi/) braucht keine Registrierung, funktioniert in jedem Gebäude und auch
an anderen Hochschulen. Zur Netzwerkdose greifst du, wenn du sie gezielt brauchst.
:::

## Was will diese Dose

Einstecken und beobachten. Erscheint eine Passwortabfrage, oder meldet dein Rechner, dass
eine Authentifizierung nötig ist, spricht die Dose 802.1X: nimm den ersten Weg unten. Wird
nichts gefragt und du bekommst einfach nie eine Adresse, prüft die Dose Hardwareadressen:
nimm den zweiten.

Es 802.1X zuerst zu versuchen kostet nichts. Eine Dose, die nicht fragt, bekommt die
Anmeldedaten nie zu sehen.

---

## Weg 1: Portauthentifizierung per 802.1X

### Dokumentierte Werte

| Punkt | Wert |
|---|---|
| Methode | ${facts.network.wired_eap} |
| Innere Methode | ${facts.network.wired_phase2} |
| Identität | `<kennung>`, ohne Realm und ohne Domäne |
| Authentifizierungsmodus | Benutzer, nicht Maschine |
| CA-Zertifikat | ${facts.network.wired_ca} |
| Zu prüfender Servername | `${facts.network.wired_domain_suffix}` |
| Anmeldeserver | `${facts.network.wired_server_name}` |

Beide Zertifikatseinstellungen sind nötig. Deine Hochschulkennung ist dasselbe Passwort,
das auch an deine Mail und an alles andere kommt, und ein Profil, das das Zertifikat des
Anmeldeservers nicht prüft, gibt es an alles weiter, was danach fragt.
[WLAN am Campus](/de/wifi/) erklärt das ausführlich, auch warum eine CA ohne zusätzlich
geprüften Servernamen den Angriff nur eingrenzt statt ihn zu schließen.

Die offizielle Anleitung setzt das Häkchen bei *Serverzertifikat überprüfen* und lässt
dann die vertrauenswürdige Stelle unausgewählt und *Verbindung mit folgenden Servern
herstellen* leer, die beiden Werte oben stammen also nicht von dort. Sie wurden am
2026-08-13 an einer Campusdose abgelesen und vor dem Aufschreiben auf anderem Weg
bestätigt. Die Netzwerkdose und ${facts.wifi.eduroam_ssid} zeigten an diesem Tag dieselbe
Zertifikatskette samt Fingerabdrücken, die WLAN-CA in `facts/wifi.yaml` und die
kabelgebundene hier benennen also einen Server.

### Der Klickweg

::: os arch

**GNOME:** Einstellungen → Netzwerk → Zahnrad der Kabelverbindung → Reiter **Sicherheit**
→ **802.1X-Sicherheit** einschalten. Authentifizierung `Protected EAP (PEAP)`, innere
Authentifizierung `${facts.network.wired_phase2}`, Benutzername `<kennung>`, Passwort dein
Hochschulpasswort.

**KDE:** Systemeinstellungen → WLAN & Netzwerk → die Kabelverbindung →
**802.1x-Sicherheit**, dieselben vier Werte.

Dann die beiden Zertifikatseinstellungen: **CA-Zertifikat** →
`${facts.wifi.eduroam_ca_path_arch}`, das ist ${facts.network.wired_ca}, wie das Paket
`ca-certificates` es ablegt, und **Domäne** (GNOME) beziehungsweise **Domain-Suffix**
(KDE) → `${facts.network.wired_domain_suffix}`.

Anonyme Identität leer lassen.

:::

::: os debian

**GNOME:** Einstellungen → Netzwerk → Zahnrad der Kabelverbindung → Reiter **Sicherheit**
→ **802.1X-Sicherheit** einschalten. Authentifizierung `Protected EAP (PEAP)`, innere
Authentifizierung `${facts.network.wired_phase2}`, Benutzername `<kennung>`, Passwort dein
Hochschulpasswort.

**KDE:** Systemeinstellungen → WLAN & Netzwerk → die Kabelverbindung →
**802.1x-Sicherheit**, dieselben vier Werte.

Dann die beiden Zertifikatseinstellungen: **CA-Zertifikat** →
`${facts.wifi.eduroam_ca_path_debian}`, das ist ${facts.network.wired_ca}, wie das Paket
`ca-certificates` es ablegt, und **Domäne** (GNOME) beziehungsweise **Domain-Suffix**
(KDE) → `${facts.network.wired_domain_suffix}`.

Anonyme Identität leer lassen.

:::

::: os macos

macOS fragt von selbst. Steck in eine Dose, die 802.1X spricht, und es erscheint eine
Anmeldeabfrage für den Ethernet-Dienst; trag `<kennung>` und dein Hochschulpasswort ein.

macOS zeigt dann das Zertifikat des Anmeldeservers und fragt, ob ihm vertraut werden soll.
Dieser Dialog ist die einzige Serverprüfung, die du hier bekommst, und er ist eine
einmalige menschliche Entscheidung statt einer Einstellung: zu erwarten ist der Name
`${facts.network.wired_server_name}`, ausgestellt unter ${facts.network.wired_ca}. Lies
ihn, bevor du zustimmst, denn Zustimmen speichert es dauerhaft.

Vorab konfigurieren: Systemeinstellungen → Netzwerk → Ethernet → Details → **802.1X**.

:::

### Der schnelle Weg im Terminal

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

`ifname` ist die Kabelschnittstelle aus `ip -brief link show`. `password-flags 2` fragt das
Passwort beim Verbinden ab, statt es zu speichern; lass es weg und ergänze
`802-1x.password "<password>"`, wenn du es lieber im Schlüsselbund behältst.

Den Profilnamen wählst du selbst. Er ist eine lokale Bezeichnung, und Campussysteme sehen
ihn nie.

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

`ifname` ist die Kabelschnittstelle aus `ip -brief link show`. `password-flags 2` fragt das
Passwort beim Verbinden ab, statt es zu speichern; lass es weg und ergänze
`802-1x.password "<password>"`, wenn du es lieber im Schlüsselbund behältst.

Den Profilnamen wählst du selbst. Er ist eine lokale Bezeichnung, und Campussysteme sehen
ihn nie.

:::

::: os macos

`networksetup` kann kein 802.1X-Profil anlegen. Nimm den Dialog oben, oder installiere ein
`.mobileconfig`-Profil, falls deine Fakultät eines verteilt.

:::

### Prüfen

<ScriptDownload file="network-verify.sh" does="Meldet das Profil, die Adresse vom Port und die Hardware-Adressen, die jeweils einzeln registriert werden müssen" />

Es deckt beide Wege auf dieser Seite ab, und `--evidence` schreibt alles Beobachtete mit.
Ein Netzwerkport ist das Einzige hier, bei dem du danebenstehen musst, deshalb ist ein
mitgeschriebener Lauf mehr wert als ein gelesener.

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

Eine Adresse aus dem Campusnetz heißt, die Anmeldung wurde akzeptiert. Eine Adresse in
`169.254.x.x`, oder gar keine, heißt, sie wurde es nicht, oder diese Dose will
stattdessen eine registrierte MAC-Adresse.

Der zweite Befehl gibt die beiden Zertifikatsfelder aus. Beide müssen gefüllt sein, und
das Suffix muss `${facts.network.wired_domain_suffix}` lauten. Ein Profil, das nur der
offiziellen Anleitung folgt, hat keines von beiden und meldet sich genauso erfolgreich an
wie eines, das beide hat, deshalb lohnt sich der Blick statt der Annahme.

---

## Weg 2: Registrierung per MAC-Adresse

### Warum Registrierung statt des offiziellen Clients

Wo eine Dose Hardwareadressen prüft, beruht die Authentifizierung auf einer Positivliste.
Der dokumentierte Weg auf diese Liste führt über ein eigenes Onboarding-Netz und den
Onboarding-Client des Herstellers.

::: os arch

Dieser Client unterstützt Windows und macOS, Linux nur sehr eingeschränkt. Für Systeme,
die er nicht abdeckt, rät die IT selbst dazu, das Gerät von Hand über das Formular für
IoT-Geräte zu registrieren. Das ist nicht bloß ein Umweg: es bedeutet, dass keine
zusätzliche Software mit Administratorrechten auf deinem Rechner läuft, was ein echter
Vorteil ist.

:::

::: os debian

Dieser Client unterstützt Windows und macOS, Linux nur sehr eingeschränkt. Für Systeme,
die er nicht abdeckt, rät die IT selbst dazu, das Gerät von Hand über das Formular für
IoT-Geräte zu registrieren. Das ist nicht bloß ein Umweg: es bedeutet, dass keine
zusätzliche Software mit Administratorrechten auf deinem Rechner läuft, was ein echter
Vorteil ist.

:::

::: os macos

Dieser Client deckt macOS ab, dir steht er also offen. Die Alternative ist die
Registrierung von Hand über das Formular für IoT-Geräte, und sie ist der Weg, den diese
Seite beschreibt: es läuft keine zusätzliche Software mit Administratorrechten auf deinem
Rechner, was ein echter Vorteil ist.

:::

Der Preis ist, dass eine manuelle Registrierung nach
${facts.network.registration_validity} abläuft und erneuert werden muss.

### Dokumentierte Werte

| Punkt | Wert |
|---|---|
| Registrierungsformular | [Formular für IoT-Geräte](${facts.network.registration_form_url}) |
| Gültig für | ${facts.network.registration_validity} |
| Zusätzlich abgedecktes WLAN | `${facts.wifi.thi_ssid}` |
| Onboarding-Netz, für den offiziellen Client | `${facts.wifi.onboard_ssid}` |

### Schritt 1: die MAC-Adressen sammeln

Jede Dose, jeder Adapter und jede Dockingstation hat eine eigene MAC-Adresse, und **jede
braucht eine eigene Registrierung**. Ein Laptop mit eingebautem Anschluss und einem Dock
sind zwei Einreichungen.

::: os arch

```bash
ip -brief link show
```

Schnittstellen mit Namen wie `enp…` oder `eth…` sind kabelgebunden, `wlp…` oder `wlan…`
sind Funk.

:::

::: os debian

```bash
ip -brief link show
```

Schnittstellen mit Namen wie `enp…` oder `eth…` sind kabelgebunden, `wlp…` oder `wlan…`
sind Funk.

:::

::: os macos

```bash
networksetup -listallhardwareports
```

Jeder Block nennt einen Hardware-Port und seine Adresse. **Ethernet** und **Thunderbolt
Ethernet** sind die kabelgebundenen, **Wi-Fi** ist der Funkanschluss.

:::

Wenn du nicht erkennst, welcher Eintrag das Dock ist, zieh es ab, führ den Befehl erneut
aus und vergleiche.

### Schritt 2: das Formular einreichen

Öffne das [Formular für IoT-Geräte](${facts.network.registration_form_url}) einmal pro
MAC-Adresse. Jede Adresse kann nur für einen Bereich freigeschaltet werden, sie taucht
also in genau einer Einreichung auf.

**Für eine Netzwerkdose:**

1. *Welche Art von Gerät möchten Sie registrieren?* → **Sonstiges (auch Linux ARM)**
2. *Benötigen Sie für das Gerät WLAN?* → **Nein**
3. *Gerätename* → `<hostname>`
4. *MAC-Adresse* → die Adresse der Kabelschnittstelle
5. *Beschreibung* → wofür es gebraucht wird, etwa Zugang für Lehre oder Forschung
6. *Betriebssystem inkl. Buildversion* → das System, das du benutzt, mit Version, so wie
   du es selbst nennen würdest
7. *Freischaltung Bereich* → der Netzbereich, den du brauchst

**Für das WLAN `${facts.wifi.thi_ssid}`:** dasselbe Formular, mit *Benötigen Sie für das
Gerät WLAN?* auf **Ja** und der MAC-Adresse der Funkschnittstelle.

### Schritt 3: warten

Mit dem Absenden beginnt ein Freigabeprozess, den ein Mensch bearbeitet. Meldungen zum
Fortschritt kommen über Teams und per Mail.

Für `${facts.wifi.thi_ssid}` bekommst du eigene Zugangsdaten. Für Ethernet bekommst du
eine allgemeine Freischaltung für Campusdosen, gültig
${facts.network.registration_validity}.

Fang früh damit an, wenn du weißt, dass du es brauchen wirst. Nichts daran geht sofort.

### Prüfen

Steck in eine Campusdose und prüfe, dass du eine Adresse aus dem Campusnetz bekommen hast
und keine selbst vergebene:

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

Eine Adresse in `169.254.x.x`, oder gar keine Adresse, heißt, die Authentifizierung war
nicht erfolgreich: die Registrierung ist noch nicht aktiv, oder diese MAC wurde nie
eingereicht.

---

## Bekannte Eigenheiten

**Die Identität trägt keinen Realm.** Kabelgebundenes 802.1X und
`${facts.wifi.thi_ssid}` wollen die nackte `<kennung>`; eduroam will
`<kennung>@${facts.wifi.eduroam_realm}`. Wer das verwechselt, bekommt einen
Authentifizierungsfehler ohne nützliche Meldung. Lass das Domänenfeld im Windows-Stil
ebenfalls leer.

**Benutzer, nicht Maschine.** Die offizielle Konfiguration authentifiziert die Person, die
Dose kommt also nach deiner Anmeldung hoch und nicht beim Start. Eine Maschine, die
erreichbar sein soll, während niemand angemeldet ist, ist eine andere Einrichtung, und
diese Seite dokumentiert keine.

**Eine MAC, ein Bereich.** Eine für einen Netzbereich registrierte Adresse kann nicht
erneut für einen anderen eingereicht werden.

**Die Erneuerung liegt bei dir.** Nichts warnt dich, bevor die
${facts.network.registration_validity} ablaufen, es hört einfach auf zu funktionieren.
Eine Kalendererinnerung nach elf Monaten ist die praktische Antwort.

**Geteilte Docks sind eine Falle, in beide Richtungen.** Bei der Registrierung gehört die
MAC zum Dock, eine Kollegin oder ein Kollege am registrierten Dock erbt also deine
Registrierung. Bei 802.1X gehören die Anmeldedaten dir und wandern mit dem Rechner, ein
geteiltes Dock ist damit nicht das Problem; die Dose, die ein zweites Gerät am selben Dock
befragt, schon.

**Referenz:** [802.1X-LAN-Konfiguration (PDF)](${facts.network.wired_official_pdf}), ein
Klickweg für Windows, hier wegen der Werte nützlich und nicht wegen der Schritte.
