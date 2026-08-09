---
title: Sichere Gerätekonfiguration unter Linux und macOS
description: Was die Hochschule von einem Dienstrechner verlangt, und was jede Regel unter Linux und macOS bedeutet.
os: [arch, debian, macos]
translatedFrom: 63052c62252ee79232017f13cb5e5896b5f16c76
---

# Sichere Gerätekonfiguration

Die Regeln für Rechner, die der Hochschule gehören. Sie sind für Windows geschrieben, was
die Entsprechungen unter Linux und macOS der Auslegung überlässt. Genau diese Auslegung
ist der Zweck dieser Seite.

::: warning Diese Seite ist nicht maßgeblich
Die Anforderungen stammen aus einem Schreiben der Hochschulleitung. Was folgt, ist eine
Lesart dieses Schreibens, verfasst ohne Befugnis zur Auslegung und ohne Haftung für die
Folgen. Wo diese Seite und der offizielle Text sich widersprechen, zählt der offizielle
Text, und den solltest du auch lesen: in MyTHI nach *"sicher an der THI"* suchen, oder
siehe [IT-Sicherheitsrichtlinien](${facts.official.kb_url}/1-it/177-it-sicherheitsrichtlinien).
:::

## Die Anforderungen

So wie sie dort stehen:

- Die **lokale Festplatte ist verschlüsselt**.
- Der **Hostname entspricht dem Aufkleber** auf der Vorderseite des Geräts (Inventarformat
  `IF…`).
- Das **Gastkonto ist deaktiviert**.
- Die **Firewall ist aktiv**, eingehende Verbindungen ohne vorherige Initialisierung
  werden blockiert. Nur einzelne notwendige Dienste dürfen geöffnet werden, eine
  pauschale Freigabe ist nicht zulässig.
- Ein **Virenscanner** ist aktiv, mit aktuellen Signaturen. Auf Windows-Dienstrechnern ist
  das Microsoft Defender.
- Das System ist **regelmäßig mit dem Campusnetz verbunden**, einmal im Monat vier Stunden
  ohne Unterbrechung, damit Betriebssystem- und Softwareupdates installiert werden.

Einen Rechner in dieses Netz zu bringen ist entweder
[eduroam und @thi WLAN](/de/wifi/) oder
[Ethernet mit 802.1X](/de/network/ethernet-802-1x).

## Was das jeweils auf deinem System bedeutet

::: os arch

| Anforderung | Unter Arch |
|---|---|
| Hostname entspricht dem Aufkleber | `hostnamectl set-hostname <inventarnummer>` |
| Gastkonto deaktiviert | Es gibt standardmäßig kein Gastkonto. Nichts zu tun. |
| Firewall, eingehend standardmäßig verboten | `ufw` oder `firewalld`; `ufw default deny incoming` trifft den Wortlaut genau |
| Festplattenverschlüsselung | LUKS auf dem Rootvolume, üblicherweise bei der Installation gewählt |
| Regelmäßige Updates | regelmäßig `pacman -Syu` |
| Virenscanner | siehe unten |

:::

::: os debian

| Anforderung | Unter Debian |
|---|---|
| Hostname entspricht dem Aufkleber | `hostnamectl set-hostname <inventarnummer>` |
| Gastkonto deaktiviert | standardmäßig kein Gastkonto |
| Firewall, eingehend standardmäßig verboten | `ufw enable` zusammen mit `ufw default deny incoming` |
| Festplattenverschlüsselung | LUKS, vom Installer angeboten |
| Regelmäßige Updates | regelmäßig `apt update && apt upgrade`, oder das Paket `unattended-upgrades`, das Sicherheitsupdates nach dem Aktivieren selbständig einspielt. Einrichtung und Konfiguration: [PeriodicUpdates im Debian-Wiki](https://wiki.debian.org/PeriodicUpdates) |
| Virenscanner | siehe unten |

:::

::: os macos

| Anforderung | Unter macOS |
|---|---|
| Hostname entspricht dem Aufkleber | Systemeinstellungen → Allgemein → Info → Name |
| Gastkonto deaktiviert | Systemeinstellungen → Benutzer & Gruppen → Gastbenutzer → aus |
| Firewall | Systemeinstellungen → Netzwerk → Firewall → ein |
| Festplattenverschlüsselung | FileVault |
| Regelmäßige Updates | automatische Updates aktiviert |
| Virenscanner | XProtect ist eingebaut und immer aktiv |

:::

## Die Frage nach dem Virenscanner

Die Anforderung nennt Microsoft Defender, weil sie für Windows geschrieben ist. Sie sagt
nicht, was die Entsprechung anderswo ist, und diese Seite kann das nicht klären.

::: os arch

Von den Distributionen selbst gibt es keine vergleichbare Erwartung, und der
Richtlinientext sagt ausdrücklich, dass es auf eigenes Risiko geht, diesen Punkt unter
Linux zu ignorieren. Übrig bleibt eine Abwägung statt eines Befehls.

ClamAV ist der quelloffene Scanner, zu dem die meisten greifen, wenn ein Häkchen gesetzt
werden muss. Standardmäßig prüft er auf Anforderung, es wird also nichts untersucht,
solange nichts danach fragt; dauerhaftes Prüfen ist ein zusätzlicher Dienst obendrauf. Ob
das die Sicherheit einer Linux-Arbeitsstation spürbar erhöht, ist eine andere Frage als
die, ob es eine Prüfung zufriedenstellt.

Einrichtung, die Dienste `clamav-daemon` und `clamav-freshclam` und wie sich dauerhaftes
Prüfen einschalten lässt: [ClamAV im ArchWiki](https://wiki.archlinux.org/title/ClamAV).

:::

::: os debian

Von den Distributionen selbst gibt es keine vergleichbare Erwartung, und der
Richtlinientext sagt ausdrücklich, dass es auf eigenes Risiko geht, diesen Punkt unter
Linux zu ignorieren. Übrig bleibt eine Abwägung statt eines Befehls.

ClamAV ist der quelloffene Scanner, zu dem die meisten greifen, wenn ein Häkchen gesetzt
werden muss. Standardmäßig prüft er auf Anforderung, es wird also nichts untersucht,
solange nichts danach fragt; dauerhaftes Prüfen ist ein zusätzlicher Dienst obendrauf. Ob
das die Sicherheit einer Linux-Arbeitsstation spürbar erhöht, ist eine andere Frage als
die, ob es eine Prüfung zufriedenstellt.

Einrichtung, die Dienste `clamav-daemon` und `clamav-freshclam` und wie sich dauerhaftes
Prüfen einschalten lässt: [ClamAV im Debian-Wiki](https://wiki.debian.org/ClamAV).

:::

::: os macos

macOS bringt XProtect mit, das Apple pflegt und das läuft, ohne installiert oder
eingeschaltet zu werden. Ob das gemeint ist, wenn die Anforderung von einem Virenscanner
spricht, ist dieselbe offene Frage wie unter Linux. Der Unterschied ist, dass es so oder
so nichts für dich zu tun gibt.

:::

## Prüfen

Es gibt keine Konformitätsprüfung zum Ausführen. Nichts hier meldet irgendwem etwas, und
diese Seite kann dir nicht sagen, ob eine Prüfstelle zustimmen würde. Was du tun kannst,
ist bestätigen, dass jede Einstellung in dem Zustand ist, den du erwartest:

<ScriptDownload file="policy-verify.sh" does="Zeigt den Zustand der Einstellungen aus den Anforderungen, nur auf diesem Rechner" />

Es druckt und speichert den Rechnernamen nie: gefordert ist, dass der Name zum
Inventaraufkleber passt, und eine Inventarnummer bezeichnet einen Rechner, der einer
Person gehört. Gemeldet wird nur, ob der Name diese Form hat.

::: os arch

```bash
hostnamectl                          # Name entspricht dem Aufkleber
sudo ufw status verbose              # aktiv, eingehend standardmäßig verboten
lsblk -o NAME,TYPE,MOUNTPOINTS,FSTYPE # nach crypto_LUKS auf dem Rootgerät suchen
```

:::

::: os debian

```bash
hostnamectl
sudo ufw status verbose
lsblk -o NAME,TYPE,MOUNTPOINTS,FSTYPE
systemctl status unattended-upgrades
```

:::

::: os macos

```bash
scutil --get ComputerName
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
fdesetup status                      # FileVault
softwareupdate --schedule
```

:::

## Bekannte Eigenheiten

**Die Regel mit den vier Stunden im Monat betrifft die Auslieferung von
Windows-Updates.** Sie existiert, damit verwaltete Windows-Rechner ihre Updates aus der
Campusinfrastruktur beziehen. Unter Linux und macOS ist die entsprechende Pflicht schlicht,
das System aktuell zu halten, was du ohnehin tust, aber der Richtlinientext sagt das nicht,
und diese Seite kann es nicht stellvertretend für die Richtlinie sagen.
