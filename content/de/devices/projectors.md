---
title: Beamer und externe Bildschirme über HDMI
description: Blasse Farben über HDMI im Hörsaal beheben, und was du vor einer Vorlesung prüfst.
os: [arch, debian, macos]
translatedFrom: 76a9026f8f68cf9b0cdaad6d923c3715e4f6394b
---

# Beamer und externe Bildschirme

Behandelt den Fehler, der fünf Minuten vor einer Vorlesung auftaucht: der Beamer läuft,
aber alles sieht falsch aus.

## Blasse Farben über HDMI

Farben wirken ausgewaschen, Schwarz wirkt grau, und der eigene Laptopbildschirm ist in
Ordnung. Oft sieht es bei niedrigerer Auflösung richtig aus, weshalb viele die Ursache
bei der Auflösung suchen.

Es ist kein Auflösungsproblem. Der Grafiktreiber sendet einen **begrenzten RGB-Bereich**
(16–235, die Fernsehkonvention), während der Beamer den **vollen Bereich** (0–255)
erwartet, das ganze Bild verliert also Kontrast.

::: os arch

```bash
xrandr --output HDMI1 --set "Broadcast RGB" "Full"
```

Den echten Ausgangsnamen liefert `xrandr` allein; er unterscheidet sich (`HDMI1`,
`HDMI-1`, `HDMI-A-0`). Ändert sich nichts, Kabel abziehen und wieder anstecken: die
Einstellung greift beim nächsten Link Training.

**Unter Wayland funktioniert das nicht.** `xrandr` kommt an die Einstellung nicht heran.
Auf Intel-Grafik ist die Entsprechung der Kernelparameter `video=HDMI-A-1:D` zusammen mit
treiberspezifischen Optionen; bei anderen Treibern gibt es unter Umständen gar keine
Kontrolle für Benutzer. Für die Vorlesung in eine X-Sitzung zu wechseln ist die
verlässliche Antwort, so unbefriedigend das ist.

:::

::: os debian

```bash
xrandr --output HDMI-1 --set "Broadcast RGB" "Full"
```

Den echten Ausgangsnamen liefert `xrandr` allein; er unterscheidet sich (`HDMI1`,
`HDMI-1`, `HDMI-A-0`). Ändert sich nichts, Kabel abziehen und wieder anstecken.

In Wayland-Sitzungen ist die Einstellung auf diesem Weg nicht erreichbar, eine X-Sitzung
ist der verlässliche Ausweg.

:::

::: os macos

macOS handelt den Bereich selbst aus und trifft es meistens richtig. Wenn nicht, ist die
Einstellung in den Systemeinstellungen nicht zugänglich. Ein Display-Override-Profil ist
der übliche Ausweg, und er ist fummelig genug, dass sich ein anderes Kabel oder ein
anderer Adapter zuerst lohnt.

:::

Hintergrund: [die askubuntu-Antwort, die denselben Fix
beschreibt](https://askubuntu.com/a/640153).

## Prüfen

<ScriptDownload file="devices-verify.sh" does="Sagt, ob dies eine Wayland-Sitzung ist, was angeschlossen ist und ob die Einstellung überhaupt existiert" />

Damit ist beantwortet, ob die Lösung oben hier verfügbar ist. Ob das Bild stimmt, ist der
Teil darunter, und kein Skript sieht eine Wand.

Zeig etwas mit einer großen schwarzen und einer großen weißen Fläche: ein Terminal auf der
einen Seite, ein weißes Dokument auf der anderen. Korrekte Ausgabe im vollen Bereich
liefert echtes Schwarz und kein Dunkelgrau.

## Bekannte Eigenheiten

**USB-C-Docks bringen einen eigenen Fehler mit.** Manche Docks handeln eine niedrigere
Linkrate aus und fallen stillschweigend auf eine niedrigere Bildwiederholrate oder
Auflösung zurück. Ist das Bild über direktes HDMI in Ordnung und über das Dock falsch, ist
das Dock die Variable.

**Spiegeln und Erweitern führen zu unterschiedlichen Modi.** Eine Auflösung, die erweitert
funktioniert, wird gespiegelt womöglich nicht angeboten, und Hörsäle wollen in der Regel
gespiegelt.

**Raumspezifisches Verhalten ist hier nicht dokumentiert.** Die Medientechnik
unterscheidet sich zwischen Gebäuden, und auf dieser Seite steht ein Fix. Wenn du
herausfindest, was ein bestimmter Raum braucht, lohnt sich das als Ergänzung.
