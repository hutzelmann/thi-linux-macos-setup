---
title: 'Ethernet am Campus: 802.1X und MAC-Registrierung'
description: 'Ein Linux- oder Mac-Gerät an eine Netzwerkdose am Campus bringen: Anmeldung per 802.1X, oder den Adapter per MAC-Adresse registrieren, und wie du erkennst, was eine Dose will.'
os: [arch, debian, macos]
translatedFrom: da5cfb6b2b0e60c26692087bf78a9e29af3e2acf
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
| CA-Zertifikat | nicht dokumentiert, siehe unten |
| Zu prüfender Servername | nicht dokumentiert, siehe unten |

::: warning Die beiden Zertifikatseinstellungen fehlen in der dokumentierten Konfiguration
Beide Campuswege tragen deine Hochschulkennung, dasselbe Passwort, das auch an deine Mail
und an alles andere kommt. [WLAN am Campus](/de/wifi/) erklärt ausführlich, warum ein
Profil, das das Zertifikat des Anmeldeservers nicht prüft, dieses Passwort an alles
weitergibt, was danach fragt, und warum eine CA ohne zusätzlich geprüften Servernamen den
Angriff nur eingrenzt statt ihn zu schließen.

Das offizielle Dokument setzt das Häkchen bei *Serverzertifikat überprüfen* und lässt dann
die vertrauenswürdige Stelle unausgewählt und *Verbindung mit folgenden Servern
herstellen* leer. Ein am Campus untersuchtes funktionierendes Profil trug ebenfalls keinen
der beiden Werte. Diese Seite kann dir also nicht sagen, was dort einzutragen ist, und sie
rät nicht: an Netzwerkdosen wird das Zertifikat gegen nichts Bestimmtes geprüft.

Die Funknetze prüfen `${facts.wifi.eduroam_domain_suffix}` gegen
${facts.wifi.eduroam_ca}. Ob die Netzwerkdosen denselben Anmeldeserver nutzen, ist genau
die offene Frage, und eine Annahme hier wäre der plausibel aussehende Wert, der schlimmer
ist als eine eingestandene Lücke. Wenn du das auf anderem Weg bestätigst, ist das ein
Issue wert.
:::

### Der Klickweg

::: os arch

**GNOME:** Einstellungen → Netzwerk → Zahnrad der Kabelverbindung → Reiter **Sicherheit**
→ **802.1X-Sicherheit** einschalten. Authentifizierung `Protected EAP (PEAP)`, innere
Authentifizierung `${facts.network.wired_phase2}`, Benutzername `<kennung>`, Passwort dein
Hochschulpasswort.

**KDE:** Systemeinstellungen → WLAN & Netzwerk → die Kabelverbindung →
**802.1x-Sicherheit**, dieselben vier Werte.

Anonyme Identität leer lassen. Das Feld für das CA-Zertifikat ist die Stelle, an die der
oben fehlende Wert gehören würde.

:::

::: os debian

**GNOME:** Einstellungen → Netzwerk → Zahnrad der Kabelverbindung → Reiter **Sicherheit**
→ **802.1X-Sicherheit** einschalten. Authentifizierung `Protected EAP (PEAP)`, innere
Authentifizierung `${facts.network.wired_phase2}`, Benutzername `<kennung>`, Passwort dein
Hochschulpasswort.

**KDE:** Systemeinstellungen → WLAN & Netzwerk → die Kabelverbindung →
**802.1x-Sicherheit**, dieselben vier Werte.

Anonyme Identität leer lassen. Das Feld für das CA-Zertifikat ist die Stelle, an die der
oben fehlende Wert gehören würde.

:::

::: os macos

macOS fragt von selbst. Steck in eine Dose, die 802.1X spricht, und es erscheint eine
Anmeldeabfrage für den Ethernet-Dienst; trag `<kennung>` und dein Hochschulpasswort ein.

macOS zeigt dann das Zertifikat des Anmeldeservers und fragt, ob ihm vertraut werden soll.
Dieser Dialog ist die einzige Serverprüfung, die du hier bekommst, und er ist eine
einmalige menschliche Entscheidung statt einer Einstellung: lies den Namen im Zertifikat,
bevor du zustimmst, denn Zustimmen speichert es dauerhaft.

Vorab konfigurieren: Systemeinstellungen → Netzwerk → Ethernet → Details → **802.1X**.

:::

### Der schnelle Weg im Terminal

::: os arch

```bash
nmcli connection add type ethernet con-name "THI 802.1X" ifname enp0s31f6 \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "<kennung>" \
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

Der zweite Befehl gibt die beiden Zertifikatsfelder aus. Beide sind in einem Profil aus
den dokumentierten Werten leer, und das ist die oben beschriebene Lücke und kein Fehler
von dir.

---

## Weg 2: Registrierung per MAC-Adresse

### Warum Registrierung statt des offiziellen Clients

Wo eine Dose Hardwareadressen prüft, beruht die Authentifizierung auf einer Positivliste.
Der dokumentierte Weg auf diese Liste führt über ein eigenes Onboarding-Netz und den
Onboarding-Client des Herstellers, der Windows und macOS unterstützt und Linux nur sehr
eingeschränkt.

Für Systeme, die er nicht abdeckt, rät die IT selbst dazu, das Gerät von Hand über das
Formular für IoT-Geräte zu registrieren. Das ist nicht bloß ein Umweg: es bedeutet, dass
keine zusätzliche Software mit Administratorrechten auf deinem Rechner läuft, was ein
echter Vorteil ist.

Der Preis ist, dass eine manuelle Registrierung nach
${facts.network.registration_validity} abläuft und erneuert werden muss.

### Dokumentierte Werte

| Punkt | Wert |
|---|---|
| Registrierungsformular | [Formular für IoT-Geräte](${facts.network.registration_form_url}) |
| Gültig für | ${facts.network.registration_validity} |
| Zusätzlich abgedecktes WLAN | `${facts.wifi.thi_ssid}` |
| Onboarding-Netz (nicht für Linux) | `${facts.wifi.onboard_ssid}` |

### Schritt 1: die MAC-Adressen sammeln

Jede Dose, jeder Adapter und jede Dockingstation hat eine eigene MAC-Adresse, und **jede
braucht eine eigene Registrierung**. Ein Laptop mit eingebautem Anschluss und einem Dock
sind zwei Einreichungen.

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

Schnittstellen mit Namen wie `enp…` oder `eth…` sind kabelgebunden, `wlp…` oder `wlan…`
sind Funk. Wenn du nicht erkennst, welcher Eintrag das Dock ist, zieh es ab, führ den
Befehl erneut aus und vergleiche.

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
6. *Betriebssystem inkl. Buildversion* → etwa "Arch Linux (Rolling Release)"
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

Eine Adresse in `169.254.x.x` (oder `link/ether` ganz ohne `inet`) heißt, die
Authentifizierung war nicht erfolgreich: die Registrierung ist noch nicht aktiv, oder
diese MAC wurde nie eingereicht.

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
