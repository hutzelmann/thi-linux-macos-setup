---
title: Netzlaufwerke (SMB) unter Linux und macOS
description: Das Homeverzeichnis am Campus und Gruppenlaufwerke unter Arch, Debian und macOS über SMB einbinden, im Dateimanager oder mit mount, am Campus oder über VPN.
os: [arch, debian, macos]
translatedFrom: a82bb889f8fc9a032f25a707ccea1fdc8f8d0800
---

# Netzlaufwerke (SMB)

Bringt dir dein Homeverzeichnis am Campus und alle Gruppenlaufwerke als Ordner auf den
Rechner, über SMB: eine `smb://`-Adresse in Dateien oder im Finder, oder `mount -t cifs`
und `mount_smbfs` für einen festen Pfad.

Offizielle Dokumentation: [Netzlaufwerk verbinden](${facts.shares.official_url}).

## Bevor du anfängst

Diese Server existieren nur innerhalb des Campusnetzes. Von überall sonst verbindest du
zuerst das [VPN](/de/vpn/openfortivpn). Alles Folgende scheitert sonst an der
Namensauflösung, was wie ein Konfigurationsfehler aussieht und keiner ist.

## Dokumentierte Werte

| Einstellung | Wert |
|---|---|
| Homeverzeichnis | `smb://${facts.shares.home_server}/<kennung>` |
| Gruppen- und Abteilungslaufwerke | `smb://${facts.shares.file_server}/` |
| Forschungslaufwerke (CARISSMA) | `smb://${facts.shares.research_server}/` |
| Domäne | `${facts.shares.domain}` |
| Benutzername | deine Hochschulkennung (`<kennung>`) |

Manche Clients haben kein eigenes Feld für die Domäne. Die wollen beides zusammen:
`${facts.shares.domain}\<kennung>`.

## Der Klickweg

Kein Terminal nötig, und für gelegentlichen Zugriff ist das die bessere Wahl: die
Verbindung verschwindet sauber, sobald du dich abmeldest.

::: os arch

In Dateien (GNOME) oder Dolphin (KDE) **Andere Orte → Mit Server verbinden** wählen und
`smb://${facts.shares.home_server}/<kennung>` eingeben. Auf Nachfrage deine Anmeldedaten
eintragen und `${facts.shares.domain}` als Domäne.

:::

::: os debian

In Dateien (GNOME) oder Dolphin (KDE) **Andere Orte → Mit Server verbinden** wählen und
`smb://${facts.shares.home_server}/<kennung>` eingeben. Auf Nachfrage deine Anmeldedaten
eintragen und `${facts.shares.domain}` als Domäne.

:::

::: os macos

Im Finder **Gehe zu → Mit Server verbinden** (`Cmd+K`), dann
`smb://${facts.shares.home_server}/<kennung>`. Wird nach einer Domäne gefragt, nimm
stattdessen `${facts.shares.domain}\<kennung>` als Benutzernamen.

*Dieses Passwort im Schlüsselbund sichern* nur auf einem Rechner ankreuzen, der dir allein
gehört.

:::

## Der Terminalweg

Nützlich, wenn du das Laufwerk an einem festen Pfad brauchst, für Skripte, Backups oder
einen Build, der daraus liest.

::: os arch

```bash
sudo pacman -S cifs-utils
mkdir -p ~/mnt/thi-home
sudo mount -t cifs //${facts.shares.home_server}/<kennung> ~/mnt/thi-home \
  -o username=<kennung>,domain=${facts.shares.domain},uid=$(id -u),gid=$(id -g)
```

:::

::: os debian

```bash
sudo apt install cifs-utils
mkdir -p ~/mnt/thi-home
sudo mount -t cifs //${facts.shares.home_server}/<kennung> ~/mnt/thi-home \
  -o username=<kennung>,domain=${facts.shares.domain},uid=$(id -u),gid=$(id -g)
```

:::

::: os macos

```bash
mkdir -p ~/mnt/thi-home
mount_smbfs "//${facts.shares.domain};<kennung>@${facts.shares.home_server}/<kennung>" \
  ~/mnt/thi-home
```

:::

`uid` und `gid` sind unter Linux wichtig: ohne sie gehört der Mount root, und dein Editor
kann nicht hineinschreiben.

Aushängen mit `sudo umount ~/mnt/thi-home` (unter macOS `umount` ohne `sudo`).

## Prüfen

<ScriptDownload file="shares-verify.sh" does="Meldet, ob die Dateiserver von deinem Standort aus erreichbar sind" />

Es beantwortet die Frage, die Leute wirklich haben: *liegt es an mir, am VPN oder am
Server?* Es werden keine Anmeldedaten verwendet und nichts eingebunden.

Von Hand:

```bash
getent hosts ${facts.shares.home_server}
```

Keine Ausgabe heißt, der Name löst nicht auf, du bist also nicht im Campusnetz und das VPN
steht nicht.

## Bekannte Eigenheiten

**Schreib dein Passwort nicht in `/etc/fstab`.** Der übliche Rat ist eine
Zugangsdatendatei mit Modus `600`, und auch die schreibt dein SSO-Passwort im Klartext auf
die Platte, dasselbe Passwort, das auch an deine Mail und deine Noten kommt. Binde bei
Bedarf ein, oder nutze einen Schlüsselbund.

**Ein hängengebliebener Mount blockiert alles, was ihn berührt.** Fällt das VPN aus,
während ein Laufwerk eingebunden ist, kann `ls` in diesem Verzeichnis minutenlang
blockieren. `sudo umount -l ~/mnt/thi-home` löst ihn sofort ab.

**Laufwerksnamen jenseits der obigen Server sind hier nicht dokumentiert.** Wenn du den
Aufbau der Gruppenlaufwerke kennst, ist das eine wirklich nützliche Ergänzung.
