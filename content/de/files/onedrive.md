---
title: OneDrive und Microsoft-365-Dateien
lastChecked:
  arch: 2026-08-09
description: Was bei OneDrive auf deinem System funktioniert, warum Drittanbieter-Clients sich nicht anmelden können, und was du stattdessen nutzt.
os: [arch, debian, macos]
translatedFrom: 829c2f7cb5ef200460058345e0b8a4b804ab92b1
---

# OneDrive und Microsoft-365-Dateien

::: os arch

Kurzfassung: **der Browser funktioniert, Drittanbieter-Clients können sich gar nicht
anmelden.** Der Grund ist eine Tenant-Richtlinie und kein Paketierungsproblem, es lohnt
sich also, das zu verstehen, bevor du einen Abend investierst.

:::

::: os debian

Kurzfassung: **der Browser funktioniert, Drittanbieter-Clients können sich gar nicht
anmelden.** Der Grund ist eine Tenant-Richtlinie und kein Paketierungsproblem, es lohnt
sich also, das zu verstehen, bevor du einen Abend investierst.

:::

::: os macos

Kurzfassung: **der Client von Microsoft funktioniert, der Browser ebenfalls.** Der
Abschnitt unten handelt von den Clients, die sich nicht anmelden können, und lohnt sich,
wenn du auch einen Linux-Rechner benutzt.

:::

Offizielle Dokumentation: [${facts.official.department}](${facts.official.service_url}).

## Warum Drittanbieter-Clients sich nicht anmelden können

Anwendungen, die Zugriff auf den Microsoft-365-Tenant der Hochschule wollen, müssen von
der IT freigegeben werden, bevor sie die Anmeldung abschließen können. Quelloffene
OneDrive-Clients registrieren sich als genau solche Anwendung.

Die Freigabe für [abraunegg/onedrive](https://abraunegg.github.io/) wurde im Juni 2025
beantragt und nicht erteilt. Solange sich das nicht ändert, kommt der Client bis zum
Anmeldebildschirm und scheitert dann. Keine lokale Konfiguration kann eine Entscheidung
umgehen, die auf dem Server getroffen wird.

Gut zu wissen, damit du das Symptom erkennst: eine Anmeldung, die mit einer Meldung über
eine nötige Administratorfreigabe endet, ist das hier und keine kaputte Installation.

## Was funktioniert

::: os arch

**Die Weboberfläche** unter [office.com](https://office.com). Einzelne Dateien öffnen,
bearbeiten und herunterladen. Nichts zu installieren.

Für Dateien, die auf der Platte liegen müssen (ein Build, ein Skript, ein Backup), sind
[Netzlaufwerke](/de/shares/smb) der unterstützte Weg, und sie brauchen keine
Fremdsoftware.

:::

::: os debian

**Die Weboberfläche** unter [office.com](https://office.com). Einzelne Dateien öffnen,
bearbeiten und herunterladen. Nichts zu installieren.

Für Dateien, die auf der Platte liegen müssen (ein Build, ein Skript, ein Backup), sind
[Netzlaufwerke](/de/shares/smb) der unterstützte Weg, und sie brauchen keine
Fremdsoftware.

:::

::: os macos

**Der offizielle OneDrive-Client von Microsoft** funktioniert normal. Installieren, mit
dem Hochschulkonto anmelden, fertig. Der Tenant gibt Microsofts eigenen Client frei.

:::

## Prüfen

Auf dem Rechner gibt es nichts zu prüfen, die Frage ist, ob sich die Tenant-Richtlinie
geändert hat. Melde dich mit dem gewünschten Client an und achte auf eine Meldung zur
Freigabe.

Wenn ein Client, der vorher scheiterte, jetzt funktioniert, ist das ein echter Befund.
Bitte
[melde ihn](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml),
denn diese Seite sagt derzeit, man solle es sein lassen.

## Bekannte Eigenheiten

**[Insync](https://www.insynchq.com/) hat hier noch niemand ausprobiert.** Es ist
kommerziell und trifft möglicherweise auf dieselbe Freigabepflicht. Ungetestet, diese
Seite kann dazu nichts sagen.

**Eine Freigabe zu beantragen ist ein legitimer Weg.** Wenn genug Leute die IT nach einem
bestimmten Client fragen, kann die Antwort sich ändern. Diese Anfrage geht an
${facts.official.support_mail} und nicht an dieses Projekt.
