---
title: Drucken am Campus unter Linux und macOS
description: Die Warteschlange ${facts.printing.queue} oder ${facts.printing.queue_students} unter Arch, Debian und macOS in CUPS einrichten, mit den lp-Rezepten für Duplex, Lochung und Heftung.
os: [arch, debian, macos]
translatedFrom: 34b9a938d4dd4156806a19ab096e8c76be5d82e4
---

# Drucken

Bringt Druckaufträge von Linux oder macOS über CUPS auf die Farbwarteschlangen im Gebäude MARB,
beidseitig, gelocht und geheftet inklusive. Auf demselben Druckserver liegen zwei
Warteschlangen: `${facts.printing.queue}` für Beschäftigte und
`${facts.printing.queue_students}` für Studierende. Alles Folgende gilt für beide, nur
der Name der Warteschlange ändert sich.

Offizielle Dokumentation: [Druckservice der THI](${facts.printing.official_url}) ·
[Wissensdatenbank: Drucken](${facts.official.kb_url}/8-drucken). Fragen zu Konto oder
Druckguthaben gehören dorthin, nicht hierher.

## Zwei Dinge vorab

**Es wird erst gedruckt, wenn du den Auftrag am Gerät freigibst.** Auftrag abschicken, zum
Gerät gehen, mit der Hochschulkarte anmelden, Auftrag auswählen. Eine Warteschlange, die
am Laptop „fertig" aussieht, ist normal und bedeutet nicht, dass der Auftrag weg ist.

**Für Eiliges brauchst du gar keinen Treiber.**
[${facts.printing.webprint_url}](${facts.printing.webprint_url}) nimmt ein PDF im Browser
entgegen und druckt es. Kein CUPS, kein PPD, kein SMB. Dafür fehlen die
Finishing-Optionen (Lochen, Heften, Versatz), und genau dafür gibt es den Rest dieser
Seite.

## Dokumentierte Werte

| Einstellung | Beschäftigte | Studierende |
|---|---|---|
| Druckserver | `${facts.printing.server}` | `${facts.printing.server}` |
| Warteschlange | `${facts.printing.queue}` | `${facts.printing.queue_students}` |
| Gerät | ${facts.printing.model} | hier nicht dokumentiert |
| SMB-Domäne | `${facts.printing.smb_domain}` | `${facts.printing.smb_domain}` |
| Benutzername | deine Hochschulkennung (`<kennung>`) | deine Hochschulkennung (`<kennung>`) |

Die Warteschlange wird über SMB angesprochen, mit demselben Protokoll und derselben
Hochschulkennung wie die [Netzlaufwerke am Campus](/de/shares/smb).

Der Server wurde von `${facts.printing.server_previous}` umbenannt. Alte Notizen und
laufende Konfigurationen tragen noch den früheren Namen. Das ist der häufigste Grund,
warum eine Einrichtung von letztem Jahr plötzlich nicht mehr funktioniert.

Welches Gerät hinter `${facts.printing.queue_students}` steht, ist hier nicht
dokumentiert. Der Treiberabschnitt geht deshalb vom selben Modell aus wie bei der
Warteschlange für Beschäftigte. Listet der Prüfschritt `Pnch` und `Stpl` auf der
studentischen Warteschlange nicht auf, trifft diese Annahme dort nicht zu, und die
Finishing-Rezepte werden abgelehnt.

## Treiber installieren

Der Hersteller liefert ein Archiv für alle Modelle, rund 250 MB, über die
[Kyocera-Downloadseite](${facts.printing.driver_url}). Einen stabilen Direktlink gibt es
nicht, unter Debian und macOS bleibt der Download also ein Handgriff. Unter Arch nimmt
ihn das AUR-Paket auf.

::: os arch

```bash
sudo pacman -S cups smbclient system-config-printer
sudo systemctl enable --now cups
```

Die PPDs kommen aus dem AUR-Paket
[`${facts.printing.driver_aur}`](${facts.printing.driver_aur_url}), das die TASKalfa-Reihe
abdeckt, zu der auch das Modell ${facts.printing.model} gehört. Mit einem AUR-Helper ist
das eine Zeile:

```bash
yay -S ${facts.printing.driver_aur}
```

Ohne Helper: `git clone https://aur.archlinux.org/${facts.printing.driver_aur}.git` und
darin `makepkg -si`. So oder so lohnt vorher ein Blick in die PKGBUILD, denn dort
entscheidet sich, ob das Herstellerarchiv während des Baus geholt wird oder daneben
liegen muss.

Das Herstellerarchiv von Hand auszupacken funktioniert ebenfalls und ist der Weg, wenn
nicht aus dem AUR gebaut werden soll. Hintergrund:
[ArchWiki: CUPS](https://wiki.archlinux.org/title/CUPS).

:::

::: os debian

```bash
sudo apt update
sudo apt install cups smbclient printer-driver-all system-config-printer
```

Anschließend das Herstellerarchiv entpacken und die EU-Variante installieren. Sie enthält
die europäischen Finishing-Optionen, unter anderem die Zweifachlochung:

```bash
tar -xzf KyoceraLinuxPackages-*.tar.gz
sudo dpkg -i KyoceraLinuxPackages-*/${facts.printing.driver_deb}
sudo apt -f install
```

Damit liegt das PPD unter `${facts.printing.ppd_path}`.

:::

::: os macos

Den macOS-Treiber von der [Herstellerseite](${facts.printing.driver_url}) installieren,
dann den Drucker über **Systemeinstellungen → Drucker & Scanner → Drucker hinzufügen**
einrichten. Dort den Reiter **Windows** (SMB) wählen, nicht IP, denn die Warteschlange
wird über SMB bereitgestellt.

Als Server `smb://${facts.printing.server}/` eintragen, dahinter die eigene
Warteschlange aus der Tabelle oben, und den Treiber für den ${facts.printing.model}
auswählen, nicht „Generic PostScript".

:::

## Warteschlange auswählen

Alle folgenden Befehle lesen die Warteschlange aus einer Shell-Variablen, damit dasselbe
Rezept für Beschäftigte und Studierende funktioniert. Einmal pro Terminal-Sitzung setzen:

```bash
# Beschäftigte
QUEUE=${facts.printing.queue}

# Studierende
QUEUE=${facts.printing.queue_students}
```

Ein neues Terminal kennt die Variable nicht. Meldet ein Befehl einen leeren
Warteschlangennamen, `QUEUE` erneut setzen.

## Warteschlange anlegen

::: os arch

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os debian

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_path}"
```

Wird das abgelehnt, statt des absoluten Pfads den CUPS-Modellnamen verwenden. Welche Form
funktioniert, hängt vom CUPS-Build ab:

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os macos

Das Hinzufügen in den Systemeinstellungen erledigt das. Als Skript:

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_model}"
```

:::

Oder das Skript nutzen: Es kennt die Werte oben und probiert die beiden PPD-Formen
automatisch nacheinander. Ohne Argumente legt es die Warteschlange für Beschäftigte an,
mit `--students` die für Studierende.

<ScriptDownload file="printing-install.sh" does="Legt die Warteschlange für Beschäftigte in CUPS an, mit --students die für Studierende, mit beiden PPD-Formen" sudo />

Beim ersten Druckauftrag fragt CUPS nach Zugangsdaten. Benutzername ist die
Hochschulkennung, Domäne `${facts.printing.smb_domain}`. Hat der Dialog kein eigenes
Domänenfeld, beides kombinieren: `${facts.printing.smb_domain}\<kennung>`.

## Prüfen

```bash
lpstat -p "$QUEUE"
lpoptions -p "$QUEUE" -l
```

Der zweite Befehl muss `Pnch` und `Stpl` auflisten. Fehlen sie, ist das Hersteller-PPD
nicht aktiv, und alle Finishing-Optionen unten werden abgelehnt.

Das Gerät hinter der Warteschlange für Beschäftigte ist mit Inserter und Locheinheit
ausgestattet. Eine Falteinheit ist möglicherweise nicht installiert. Fehlt eine Option in
`lpoptions`, ist die zugehörige Hardware am Gerät nicht konfiguriert oder nicht im PPD
hinterlegt.

<ScriptDownload file="printing-verify.sh" does="Prüft Warteschlange, Server und Finishing-Optionen; mit --students für die studentische Warteschlange" />

## Rezepte

A4, einseitig und beidseitig:

```bash
lp -d "$QUEUE" -o media=A4 datei.pdf
lp -d "$QUEUE" -o media=A4 -o sides=two-sided-long-edge datei.pdf
```

`-o KSCREENMODE="Resolution"` wählt das feinere Raster, das helle graue Flächen und feine
Linien brauchen (etwa das graue Gitter im Hintergrund eines Klausurbogens), damit sie als
gleichmäßiger Ton statt als grobes Muster herauskommen. Auf Seiten, die es nicht
brauchen, kostet es nichts, deshalb steht es in allen folgenden Rezepten und kann aus
jedem davon entfallen.

Gelocht:

```bash
lp -d "$QUEUE" -o media=A4 -o Pnch=2HoleEUR -o KSCREENMODE="Resolution" datei.pdf
```

Die Klausurkombination, beidseitig, gelocht, hinten geheftet, 25 Kopien:

```bash
lp -d "$QUEUE" -n 25 -o media=A4 -o sides=two-sided-long-edge \
   -o Pnch=2HoleEUR -o Stpl=Rear -o KSCREENMODE="Resolution" datei.pdf
```

`Stpl=Rear` ist die übliche Position, `Stpl=Front` heftet unten auf der Seite.

A4-Inhalt auf A3 skaliert:

```bash
lp -d "$QUEUE" -o media=A3 -o fit-to-page -o sides=two-sided-long-edge \
   -o Pnch=2HoleEUR -o Stpl=Front -o KSCREENMODE="Resolution" datei.pdf
```

Etiketten, über den manuellen Einzug rechts, Etiketten nach unten:

```bash
lp -d "$QUEUE" -o media=A4 -o InputSlot=MF1 -o MediaType=Labels \
   -o KSCREENMODE="Resolution" datei.pdf
```

Viele Dokumente am Stück, jeweils versetzt abgelegt:

```bash
for p in *.pdf; do
  lp -d "$QUEUE" -o media=A4 -o sides=two-sided-long-edge \
     -o Pnch=2HoleEUR -o Sep="Jog" -o KSCREENMODE="Resolution" "$p"
  sleep 1
done
```

`lpoptions -p "$QUEUE" -l` zeigt die vollständige Liste. Das PPD bietet darüber hinaus
Trapping, Überdrucken, Farbmodell, Glanzmodus und Auflösung.

## Wieder entfernen

Die Warteschlange zu entfernen ist ein Befehl und umkehrbar: Der Schritt zum Anlegen holt
sie zurück.

```bash
sudo lpadmin -x "$QUEUE"
```

Wenn beide Warteschlangen angelegt wurden, beide namentlich entfernen:

```bash
sudo lpadmin -x ${facts.printing.queue}
sudo lpadmin -x ${facts.printing.queue_students}
```

Damit verschwindet auch die Kopie des PPD, die CUPS unter `/etc/cups/ppd/` für die
Warteschlange angelegt hat. Prüfen, dass nichts übrig ist:

```bash
lpstat -p    # die Warteschlange taucht nicht mehr auf
lpstat -v    # kein smb://-Gerät zeigt mehr auf den Druckserver
```

Das Passwort vom ersten Druckauftrag liegt nicht bei CUPS, sondern im Schlüsselbund der
Arbeitsumgebung (GNOME Keyring, KWallet), unter macOS im Login-Schlüsselbund, abgelegt
unter dem Namen des Druckservers. Wer es loswerden will, löscht es dort.

Danach der Treiber. Er hängt nicht an der Warteschlange und lohnt sich zu behalten, wenn
anderswo auf demselben Modell gedruckt wird.

::: os arch

```bash
sudo pacman -Rns ${facts.printing.driver_aur}
```

Wird CUPS gleich mit entfernt, ist Drucken insgesamt weg, nicht nur auf dem Campus:

```bash
sudo systemctl disable --now cups
sudo pacman -Rns cups smbclient system-config-printer
```

:::

::: os debian

Wie das Paket heißt, hängt von der installierten Variante des Herstellerarchivs ab. Statt
zu raten, `dpkg` fragen, welches Paket das PPD mitbringt:

```bash
dpkg -S ${facts.printing.ppd_path}
sudo apt purge <Paketname aus der Zeile darüber>
```

Ist die PPD-Datei schon weg, das Paket aber nicht, findet `dpkg -l | grep -i kyo` es.
CUPS und der SMB-Client sind gewöhnliche Debian-Pakete, und mit ihnen verschwindet das
Drucken komplett:

```bash
sudo apt purge cups smbclient system-config-printer
```

:::

::: os macos

Den Drucker in den **Systemeinstellungen → Drucker & Scanner** auswählen und mit dem
Minus-Knopf entfernen. Das ist dieselbe Operation wie `lpadmin -x` oben.

Der Treiber liegt unter `/Library/Printers/`. Vor dem Löschen nachsehen, dort stehen auch
selbst eingerichtete Drucker:

```bash
ls /Library/Printers/
```

Der Download des Herstellers enthält einen Uninstaller. Wer das Image noch hat, nimmt
diesen Weg des Herstellers; er erwischt auch die Teile, die ein `rm` übersieht.

:::

Eine leere `/etc/samba/smb.conf`, falls sie beim Einrichten angelegt wurde, kann bleiben.
Andere SMB-Werkzeuge erwarten die Datei ohnehin.

## Bekannte Eigenheiten

**Ein Glob funktioniert nicht als Stapel.** `lp -d "$QUEUE" ... *.pdf` tut still nicht
das, wonach es aussieht. Nimm eine `for`-Schleife.

**Schnelle Schleifen laufen in Anmeldeverzögerungen.** Direkt aufeinanderfolgende Aufträge
können in der SMB-Authentifizierung hängen bleiben. Ein `sleep 1` dazwischen hilft. Wenn
Aufträge feststecken: Warteschlange in `system-config-printer` aktualisieren und erneut
versuchen.

**CUPS braucht nach dem Anlegen manchmal zwei Neustarts**, bevor der erste Auftrag
durchgeht. Unter Debian mit KDE beobachtet; harmlos, aber verwirrend.

**Unter KDE muss der erste Auftrag eventuell ausdrücklich authentifiziert werden.** Bleibt
er in der Warteschlange stehen: Warteschlange öffnen, Rechtsklick auf den Auftrag,
*Authentifizieren*.

**Eine fehlende `/etc/samba/smb.conf` bricht das SMB-Backend** auf manchen Systemen. Eine
leere Datei genügt:

```bash
sudo mkdir -p /etc/samba && sudo touch /etc/samba/smb.conf
```

**Es kommt nichts heraus und die Warteschlange ist leer.** Genau so ist es gedacht. Geh
zum Gerät und gib den Auftrag mit deiner Karte frei. Nicht freigegebene Aufträge verfallen
nach ${facts.printing.job_retention}.
