---
title: Drucken auf ${facts.printing.queue}
description: Die Warteschlange des ${facts.printing.model} unter Arch, Debian und macOS einrichten, mit lp-Rezepten für Duplex, Lochung, Heftung und Etiketten.
status: structured
os: [arch, debian, macos]
translatedFrom: 52dfbfb6e2573ea9be659a1757448ba947c9fef9
---

# Drucken auf ${facts.printing.queue}

Bringt Druckaufträge von Linux oder macOS auf den ${facts.printing.model} im Gebäude
MARB — beidseitig, gelocht und geheftet inklusive.

Offizielle Dokumentation: [Druckservice der THI](${facts.printing.official_url}) ·
[Wissensdatenbank: Drucken](${facts.official.kb_url}/8-drucken). Fragen zu Konto oder
Druckguthaben gehören dorthin, nicht hierher.

## Zwei Dinge, die alle überraschen

**Es wird erst gedruckt, wenn du den Auftrag am Gerät freigibst.** Auftrag abschicken, zum
Gerät gehen, mit der Hochschulkarte anmelden, Auftrag auswählen. Eine Warteschlange, die
am Laptop „fertig" aussieht, ist normal und bedeutet nicht, dass der Auftrag weg ist.

**Für Eiliges brauchst du gar keinen Treiber.**
[${facts.printing.webprint_url}](${facts.printing.webprint_url}) nimmt ein PDF im Browser
entgegen und druckt es. Kein CUPS, kein PPD, kein SMB. Dafür fehlen die
Finishing-Optionen — Lochen, Heften, Versatz — und genau dafür gibt es den Rest dieser
Seite.

## Dokumentierte Werte

| | |
|---|---|
| Druckserver | `${facts.printing.server}` |
| Warteschlange | `${facts.printing.queue}` |
| Gerät | ${facts.printing.model} |
| SMB-Domäne | `${facts.printing.smb_domain}` |
| Benutzername | deine Hochschulkennung (`<kennung>`) |

Der Server wurde von `${facts.printing.server_previous}` umbenannt. Alte Notizen und
laufende Konfigurationen tragen noch den früheren Namen — das ist der häufigste Grund,
warum eine Einrichtung von letztem Jahr plötzlich nicht mehr funktioniert.

## Treiber installieren

Der Hersteller liefert ein Archiv für alle Modelle, rund 250 MB, über die
[Kyocera-Downloadseite](${facts.printing.driver_url}). Einen stabilen Direktlink gibt es
nicht, dieser Schritt bleibt also auf jedem System manuell.

::: os arch

```bash
sudo pacman -S cups smbclient system-config-printer
sudo systemctl enable --now cups
```

Das PPD kommt aus dem AUR-Paket
[`kyocera-cups`](https://aur.archlinux.org/packages/kyocera-cups) oder aus dem Archiv des
Herstellers. Hintergrund: [ArchWiki: CUPS](https://wiki.archlinux.org/title/CUPS).

:::

::: os debian

```bash
sudo apt update
sudo apt install cups smbclient printer-driver-all system-config-printer
```

Anschließend das Herstellerarchiv entpacken und die EU-Variante installieren — sie enthält
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
einrichten. Dort den Reiter **Windows** (SMB) wählen, nicht IP — die Warteschlange wird
über SMB bereitgestellt.

Als Server `smb://${facts.printing.server}/${facts.printing.queue}` eintragen und den
Treiber für den ${facts.printing.model} auswählen, nicht „Generic PostScript".

:::

## Warteschlange anlegen

::: os arch

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os debian

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_path}"
```

Wird das abgelehnt, statt des absoluten Pfads den CUPS-Modellnamen verwenden — welche Form
funktioniert, hängt vom CUPS-Build ab:

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os macos

Das Hinzufügen in den Systemeinstellungen erledigt das. Als Skript:

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_model}"
```

:::

Oder das Skript nutzen: Es kennt die Werte oben und probiert die beiden PPD-Formen
automatisch nacheinander.

<ScriptDownload file="printing-install.sh" does="Legt die Warteschlange in CUPS an, mit beiden PPD-Formen" sudo />

Beim ersten Druckauftrag fragt CUPS nach Zugangsdaten. Benutzername ist die
Hochschulkennung, Domäne `${facts.printing.smb_domain}`. Hat der Dialog kein eigenes
Domänenfeld, beides kombinieren: `${facts.printing.smb_domain}\<kennung>`.

## Prüfen

```bash
lpstat -p ${facts.printing.queue}
lpoptions -p ${facts.printing.queue} -l
```

Der zweite Befehl muss `Pnch` und `Stpl` auflisten. Fehlen sie, ist das Hersteller-PPD
nicht aktiv, und alle Finishing-Optionen unten werden abgelehnt.

Das Gerät ist mit Inserter und Locheinheit ausgestattet. Eine Falteinheit ist
möglicherweise nicht installiert — fehlt eine Option in `lpoptions`, ist die zugehörige
Hardware am Gerät nicht konfiguriert oder nicht im PPD hinterlegt.

<ScriptDownload file="printing-verify.sh" does="Prüft Warteschlange, Server und Finishing-Optionen" />

## Rezepte

A4, einseitig und beidseitig:

```bash
lp -d ${facts.printing.queue} -o media=A4 datei.pdf
lp -d ${facts.printing.queue} -o media=A4 -o sides=two-sided-long-edge datei.pdf
```

Gelocht, und die Klausurkombination — beidseitig, gelocht, hinten geheftet, 25 Kopien:

```bash
lp -d ${facts.printing.queue} -o media=A4 -o Pnch=2HoleEUR datei.pdf

lp -d ${facts.printing.queue} -n 25 -o media=A4 -o sides=two-sided-long-edge \
   -o Pnch=2HoleEUR -o Stpl=Rear klausur.pdf
```

`Stpl=Rear` ist die übliche Position, `Stpl=Front` heftet unten auf der Seite.

A4-Inhalt auf A3 skaliert:

```bash
lp -d ${facts.printing.queue} -o media=A3 -o fit-to-page \
   -o sides=two-sided-long-edge -o Pnch=2HoleEUR -o Stpl=Front p001.pdf
```

Etiketten, über den manuellen Einzug rechts, Etiketten nach unten:

```bash
lp -d ${facts.printing.queue} -o media=A4 -o InputSlot=MF1 -o MediaType=Labels etiketten.pdf
```

Viele Dokumente am Stück, jeweils versetzt abgelegt:

```bash
for p in *.pdf; do
  lp -d ${facts.printing.queue} -o media=A4 -o sides=two-sided-long-edge \
     -o Pnch=2HoleEUR -o Sep="Jog" "$p"
  sleep 1
done
```

Feinere Rasterung für Dokumente mit Barcodes oder feinen Linien:

```bash
lp -d ${facts.printing.queue} -o media=A4 -o KSCREENMODE="Resolution" scan.pdf
```

`lpoptions -p ${facts.printing.queue} -l` zeigt die vollständige Liste — das PPD bietet
darüber hinaus Trapping, Überdrucken, Farbmodell, Glanzmodus und Auflösung.

## Bekannte Eigenheiten

**Ein Glob funktioniert nicht als Stapel.** `lp -d ${facts.printing.queue} ... *.pdf` tut
still nicht das, wonach es aussieht. Nimm eine `for`-Schleife.

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

**Es kommt nichts heraus und die Warteschlange ist leer.** Genau so ist es gedacht — geh
zum Gerät und gib den Auftrag mit deiner Karte frei. Nicht freigegebene Aufträge verfallen
nach einiger Zeit.
