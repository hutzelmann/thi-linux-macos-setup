---
title: Ein neuer Linux- oder Mac-Rechner am Campus
description: Die Reihenfolge, in der ein Linux- oder Mac-Laptop für den Campus eingerichtet wird, von den Geräteregeln über das Netz bis zu Drucken und Netzlaufwerken.
translatedFrom: a4be73cd506fecd4008b0c322fa63c049ec72b24
---

# Ein neuer Rechner am Campus

Die Reihenfolge, in der du vorgehst. Jeder Schritt verlinkt die Seite mit den Details,
komm für den nächsten Schritt hierher zurück. Kein Terminal nötig, außer dort, wo eine
Seite es als schnelleren Weg anbietet.

## 0. Prüfen, ob die Geräteregeln für dich gelten

[Sichere Gerätekonfiguration](/de/policy/secure-device-config)

Gilt nur für Hardware der Hochschule, also für Geräte mit Inventaraufkleber. Dein eigener
Laptop fällt nicht darunter.

Lies das vor der Installation und nicht danach. Festplattenverschlüsselung, Hostname und
Firewall werden während der Installation entschieden.

**Überspringen, wenn:** der Laptop dir gehört.

## 1. Ins Netz kommen

[WLAN: eduroam und @thi](/de/wifi/)

Nimm eduroam. Es funktioniert hier und an jeder anderen Hochschule, und es braucht keine
Registrierung.

Richte es mit dem [Konfigurationswerkzeug](${facts.wifi.cat_url}) ein und nicht von Hand.
Von Hand geschriebene Profile lassen sehr häufig die Prüfung weg, die einen gefälschten
Accesspoint daran hindert, dein Hochschulpasswort einzusammeln, und das Netz funktioniert
in beiden Fällen, du würdest es also nie bemerken.

**Fertig, wenn:** du online bist und die Verbindung sowohl ein CA-Zertifikat als auch
einen zu prüfenden Servernamen trägt. Der Befehl dazu steht auf der Seite.

## 2. Das Kabelnetz, nur falls du es brauchst

[Ethernet: 802.1X und Geräteregistrierung](/de/network/ethernet-802-1x)

Für Netzwerkdosen und Dockingstationen. Die meisten Dosen fordern den Rechner auf, sich
mit deiner Hochschulkennung anzumelden, das sind vier Einstellungen und keine Wartezeit.
Manche prüfen weiterhin die Hardwareadresse des Adapters gegen eine Liste, und auf diese
Liste zu kommen ist ein Formular, das ein Mensch genehmigt, fang also früh an, wenn eine
Dose stumm bleibt. Eine Registrierung läuft nach
${facts.network.registration_validity} ab.

**Überspringen, wenn:** du nur WLAN nutzt.

**Fertig, wenn:** du das WLAN ausschalten kannst und über das Kabel weiterhin eine
Webseite öffnest.

## 3. VPN

[VPN von außerhalb des Campus](/de/vpn/openfortivpn)

Außerhalb des Campus nötig für Netzlaufwerke und manche Bibliotheksressourcen. Ein
einmaliger Zertifikatsschritt, weil das Gateway seine Kette nicht vollständig ausliefert,
danach ist es ein Befehl.

**Fertig, wenn:** der Tunnel von außerhalb des Campus steht und eine interne Adresse
antwortet, etwa ein Netzlaufwerk.

## 4. Drucken

[Drucken](/de/printing/)

Der Treiber ist ein großer manueller Download. In Eile lässt du ihn weg und nutzt
[${facts.printing.webprint_url}](${facts.printing.webprint_url}) im Browser, ganz ohne
Einrichtung, um den Preis der Finishing-Optionen (Lochung und Heftung).

So oder so wartet der Auftrag auf dem Server und nicht am Drucker, der letzte Schritt
bleibt also immer deiner: zu einem Gerät gehen und ihn mit der Hochschulkarte freigeben.

**Fertig, wenn:** eine gesendete Seite aus dem Gerät kommt, nachdem du sie dort
freigegeben hast.

## 5. Netzlaufwerke

[Netzlaufwerke (SMB)](/de/shares/smb)

Dein Homeverzeichnis und Gruppenlaufwerke als Ordner auf deinem Rechner. Nur im
Campusnetz oder über VPN.

**Fertig, wenn:** die Dateiserver von deinem Standort aus auflösbar sind. Auf der Seite
liegt ein Skript, das genau das beantwortet.

## Wenn das läuft

Der Rest der Seiten gehört nicht zur Einrichtungsreihenfolge, jede Seite steht für sich.

- [OneDrive und Microsoft 365 unter Linux](/de/files/onedrive), für die Dateien, die im
  Microsoft-Tenant der Hochschule liegen statt auf einem Dateiserver.
- [Windows 11 Education in einer virtuellen Maschine](/de/vm/windows), für die Handvoll
  Programme ohne Linux-Version.
- [Beamer und externe Bildschirme über HDMI](/de/devices/projectors), lohnt sich vor dem
  ersten Anschließen im Hörsaal statt fünf Minuten danach.
