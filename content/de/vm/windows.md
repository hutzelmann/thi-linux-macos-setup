---
title: Windows 11 Education in einer virtuellen Maschine
description: Windows 11 Education unter Linux und macOS in einer VM installieren, mit GNOME Boxes, virt-manager oder UTM, mit lokalen Administratorrechten trotz Hochschulkonto.
os: [arch, debian, macos]
translatedFrom: 0eabd91c51c713ec857139c43c8c058854e19769
---

# Windows in einer virtuellen Maschine

Für die Handvoll Programme ohne Version für dein System. Ziel ist eine VM, in der **du**
lokaler Administrator bist und die trotzdem über dein Hochschulkonto an
Campusressourcen kommt, darunter [Netzlaufwerke](/de/shares/smb) und
[Drucken](/de/printing/).

## Der Fehler, der dich die Maschine kostet

Während der Windows-Einrichtung wirst du gefragt: *"Für Arbeit oder Schule/Uni
einrichten"*.

**Trag dort nicht deine Hochschul-Anmeldedaten ein.** Damit wird die VM von Anfang an ein
verwaltetes Gerät, und du stehst ohne lokales Administratorkonto da, also ohne genau das,
wofür eine VM da ist.

Wähle stattdessen **Anmeldeoptionen → Domänenbeitritt** und lege ein lokales Konto mit
einem beliebigen Namen und Passwort an, die nicht deine Hochschul-Anmeldedaten sind. Das
Hochschulkonto verbindest du danach aus Windows heraus, wenn du die Administratorrechte
bereits hast.

## Das Image besorgen

1. [Azure Dev Tools for Teaching](${facts.official.service_url}softwareangebote/microsoft-imagine)
   ([direkt](https://azureforeducation.microsoft.com/devtools)), mit den
   Hochschul-Anmeldedaten anmelden.
2. Nach "education" suchen → **Azure Education | Overview** → *Free Software* → **Explore
   All** → nach "Windows 11" suchen.
3. **Windows 11 Education** herunterladen. Nicht die N-Edition, die kommt ohne
   Mediencodecs.
4. Den Lizenzschlüssel aus der Seitenleiste notieren, die Einrichtung fragt danach.

::: os macos

Das Image aus dem Katalog ist x86-64, und ein Mac mit Apple Silicon führt ARM64-Windows
aus. Das x86-64-Image zu emulieren ist langsam genug, dass es sich nicht lohnt, nimm auf
einem M-Rechner also den ARM64-Build: [CrystalFetch](https://github.com/TuringSoftware/CrystalFetch)
von den Autoren von UTM baut eine ISO aus Microsofts eigenem
[Windows-11-Arm64-Download](https://www.microsoft.com/en-us/software-download/windows11arm64).

Ob der Lizenzschlüssel aus dem Bildungskatalog eine ARM64-Installation aktiviert, ist hier
nicht dokumentiert. Wenn du es so oder so herausfindest,
[sag bitte Bescheid](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml).

Ein Intel-Mac nimmt das Katalog-Image unverändert.

:::

## Die VM vorbereiten

Vernünftige Ausgangsgröße, unabhängig vom Werkzeug:

- 8–12 GB RAM
- 4 CPUs
- 128 GB Speicher

<ScriptDownload file="vm-verify.sh" does="Prüft am Wirtsystem Hardwarebeschleunigung, UEFI-Firmware und den Software-TPM, den der Gast braucht" />

Windows 11 verlangt Secure Boot und ein TPM. Beides sauber einzurichten ist am Anfang mehr
Arbeit, und es ist die Voraussetzung dafür, das Hochschulkonto später zu verbinden: die
Sicherheitsrichtlinien greifen nicht in einer VM, die die Prüfung umgangen hat.

::: os arch

GNOME Boxes für den kurzen Weg, virt-manager, wenn du Firmware und TPM selbst in der Hand
haben willst:

```bash
sudo pacman -S gnome-boxes
# oder
sudo pacman -S virt-manager qemu-full edk2-ovmf swtpm
```

[How to run Windows 11 in GNOME Boxes with UEFI and TPM2](https://www.ctrl.blog/entry/how-to-win11-in-gnome-boxes.html)
deckt die Firmwareseite ab. Für eine Wegwerf-VM, die nie ein Hochschulkonto verbindet, ist
der schnellere Weg über Registry-Schlüssel während der Einrichtung und dann `setup.exe`:
[Diskussion und die genauen Schlüssel](https://www.reddit.com/r/gnome/comments/q1wy49/install_windows_11_in_gnome_boxes/).

:::

::: os debian

GNOME Boxes für den kurzen Weg, virt-manager, wenn du Firmware und TPM selbst in der Hand
haben willst:

```bash
sudo apt install gnome-boxes
# oder
sudo apt install virt-manager qemu-system-x86 ovmf swtpm-tools
```

[How to run Windows 11 in GNOME Boxes with UEFI and TPM2](https://www.ctrl.blog/entry/how-to-win11-in-gnome-boxes.html)
deckt die Firmwareseite ab. Für eine Wegwerf-VM, die nie ein Hochschulkonto verbindet, ist
der schnellere Weg über Registry-Schlüssel während der Einrichtung und dann `setup.exe`:
[Diskussion und die genauen Schlüssel](https://www.reddit.com/r/gnome/comments/q1wy49/install_windows_11_in_gnome_boxes/).

:::

::: os macos

[UTM](https://docs.getutm.app/guides/windows/), kostenlos und quelloffen. Ab Version 4.3
schaltet es für Windows-Gäste UEFI Secure Boot und ein TPM-2.0-Gerät selbst ein, die
Firmwarefrage oben stellt sich also nicht.

Auf Apple Silicon ist der Gast ARM64-Windows und läuft virtualisiert statt emuliert, die
einzige Kombination, die schnell genug zum Arbeiten ist.

:::

## Nach der Installation

- Den Rechnernamen auf etwas Sinnvolles ändern, etwa `<inventarnummer>-VM`.
- Vor allem anderen Windows Update laufen lassen.

Gasttreiber, ohne die die VM langsam ist und der Bildschirm die Größe nicht anpasst:

::: os arch

Die [virtio-Treiber](https://github.com/virtio-win/virtio-win-pkg-scripts), aus Windows
heraus installiert.

:::

::: os debian

Die [virtio-Treiber](https://github.com/virtio-win/virtio-win-pkg-scripts), aus Windows
heraus installiert.

:::

::: os macos

UTMs eigene [Guest Tools](https://docs.getutm.app/guest-support/windows/), die es in die
laufende VM einhängen kann.

:::

## Das Hochschulkonto verbinden

Funktioniert nur, wenn die VM die Sicherheitsanforderungen erfüllt: Secure Boot und TPM
konfiguriert.

**Einstellungen → Konten → Arbeits- oder Schulkonto hinzufügen**, dann deine
Hochschul-Anmeldedaten. Danach greifen die Richtlinien, und mehrere Dinge passieren
nacheinander:

- Einrichtung von Windows Hello
- eine Passwortänderung
- BitLocker-Verschlüsselung, mit einem Wiederherstellungsschlüssel; sichere ihn außerhalb
  der VM

Danach können Microsoft-Anwendungen die Hochschulidentität nutzen.

## Prüfen

Drei Dinge zeigen dir, dass die VM richtig geworden ist:

1. **Du bist lokaler Administrator.** `net localgroup administrators` in einer Eingabe
   mit erhöhten Rechten listet dein lokales Konto.
2. **Secure Boot und TPM sind aktiv**, falls du das Hochschulkonto anhängen willst:
   `msinfo32` ausführen und *Secure Boot-Status: Ein* prüfen, und `tpm.msc` meldet ein
   betriebsbereites TPM.
3. **Das Hochschulkonto hängt sauber daran.** Einstellungen → Konten zeigt es unter *Auf
   Arbeits- oder Schulkonto zugreifen*, und dein lokales Administratorkonto besteht
   daneben weiter.

Wenn Punkt drei geklappt hat, Punkt eins jetzt aber nicht, ist der Fehler aus der
Einrichtung oben passiert. Der schnellste Ausweg ist neu installieren statt entwirren.

## Bekannte Eigenheiten

**Die Einrichtung ohne Netzverbindung** ist manchmal nötig, um ein lokales Konto zu
erzwingen. Beim Education-Image schien das nicht erforderlich, aber wenn die Einrichtung
auf einem Microsoft-Konto besteht, ist
[der OOBE-Bypass](https://learn.microsoft.com/en-us/answers/questions/2350856/set-up-windows-11-without-internet-oobebypassnro)
der übliche Weg.

**BitLocker-Wiederherstellungsschlüssel müssen die VM verlassen.** Ein Schlüssel, der nur
in der Maschine liegt, die er entsperrt, ist kein Backup. Druck ihn aus, oder kopiere ihn
auf den Host, bevor du ihn brauchst.

**Microsoft ändert den Einrichtungsablauf häufig.** Diese Seite beschreibt, was zum
Zeitpunkt des Schreibens funktioniert hat; wenn ein Schritt sich verschoben hat,
[melde das bitte](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml).
