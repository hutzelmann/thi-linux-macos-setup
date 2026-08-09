---
title: Wie diese Seiten gepflegt werden
description: Was dieses Projekt ist, was es mit dem Campusnetz niemals tut, und wie du beiträgst.
translatedFrom: a4f42489e898fa7db0d235101f2095850a660cd3
---

# Wie diese Seiten gepflegt werden

## Was dieses Projekt ist

Von der Community geschriebene Einrichtungsnotizen für Linux und macOS an der THI. Alle
können sie lesen, alle können sie korrigieren, und sie sind gemeinfrei.

## Was dieses Projekt nicht ist

Nicht offiziell. Keine Verbindung zur Hochschul-IT, nicht von ihr unterstützt, nicht in
ihrem Namen. Kein Supportkanal, und keine Stelle, die dein Konto reparieren kann.

Es gibt hier keine Zusagen: keine Garantie auf Richtigkeit, kein Versprechen, dass ein
Thema behandelt wird, keine Reaktionszeit. Was dieses Projekt anbietet, ist eine
Rückmeldeschleife: wenn etwas falsch ist, sag es, und es wird offen korrigiert.

Für alles, was dein Konto, dein Kontingent oder deine Hardware betrifft, sind die
offiziellen Wege die, die tatsächlich etwas ändern können:

- **[${facts.official.department}](${facts.official.service_url})**: die
  Informationsseiten der Hochschule selbst.
- **[Wissensdatenbank](${facts.official.kb_url})**: die öffentlichen Artikel der THI.
  Überwiegend auf Windows ausgerichtet, weshalb es dieses Projekt gibt, aber maßgeblich,
  wo sie sich überschneiden.
- **${facts.official.support_mail}**: wo ein Mensch antwortet. Die IT-Seiten geben an,
  dass Support derzeit per Mail läuft.

Beachte, dass [${facts.official.ticket_url}](${facts.official.ticket_url}) für sich
genommen das Ticketsystem ist und eine Anmeldung braucht; die Wissensdatenbank liegt unter
`/help` auf demselben Host.

## Warum Seiten Daten tragen statt Häkchen

Campusinfrastruktur ändert sich leise. Ein Druckserver wird umbenannt, eine
Zertifizierungsstelle wechselt, ein Hostname zieht um, und vor einem halben Jahr
geschriebene Notizen passen nicht mehr zur Wirklichkeit, ohne dass es jemand merkt.

Deshalb sagen Seiten, **wann ein Mensch sie zuletzt geprüft hat**, und manche sagen
deutlich, dass es niemand getan hat. Ein Datum, das du selbst einschätzen kannst, ist mehr
wert als ein grüner Haken, der nichts bedeutet.

## Was dieses Projekt mit dem Campusnetz niemals tut

Das gehört deutlich gesagt, denn ein Projekt, das Infrastruktur ungefragt dokumentiert,
sollte über die eigenen Grenzen genau sein:

- **Nirgends Zugangsdaten.** Nicht in diesem Repository, nicht in der Automatisierung,
  nicht in irgendeinem Skript hier. Das Hochschulpasswort ist ein universelles
  Zugangsmittel, das an Mail, Noten und personenbezogene Daten reicht, und keine
  Bequemlichkeit rechtfertigt, es zu speichern oder zu automatisieren.
- **Kein Scannen.** Prüfungen sprechen nur mit bereits dokumentierten Endpunkten, mit
  gewöhnlichen Clientprotokollen, im Umfang einer einzelnen gewöhnlichen Nutzung. Keine
  Bereiche, keine Aufzählung, nichts, was einem Abtasten ähnelt.
- **Keine automatischen Vertrauensänderungen.** Zertifizierungsstellen und Fingerabdrücke
  werden ausschließlich von einem Menschen geändert, der sie auf anderem Weg bestätigt
  hat. Ein beobachteter Wert wird nie automatisch zu einem dokumentierten.
- **Keine personenbezogenen Daten.** Benutzernamen, Adressen und Pfade werden durch
  Platzhalter ersetzt, und der Build schlägt fehl, wenn etwas durchrutscht.

## Wie du eine Seite korrigierst oder bestätigst

Korrekturen sind das Wertvollste, und die Hürde ist bewusst niedrig.

- **Etwas auf einer Seite falsch?** Nimm den Link unten auf der Seite. Die Meldung kommt
  mit bereits eingetragener Seite an.
- **Die Schritte ausprobiert und sie haben funktioniert?** Nimm *Hat bei mir funktioniert*
  unten auf jeder Seite mit Schritten. Das ist der Beitrag, der am meisten gebraucht wird,
  und der, den dieses Projekt bis vor Kurzem gar nicht annehmen konnte.
- **Direkt bearbeiten?** Jede Seite hat einen Link *Diese Seite auf GitHub bearbeiten*.
  Keine lokale Einrichtung, keine Git-Kenntnisse nötig, den Rest erledigt GitHub.

Beiträge werden unter CC0 gemeinfrei veröffentlicht, und pseudonyme Beiträge sind in
Ordnung. Einen Workaround unter dem eigenen Namen zu dokumentieren, trägt für Studierende
mehr Risiko als für Beschäftigte, und gleiche Beteiligung sollte nicht gleiche
Sichtbarkeit voraussetzen.

## Was nach einer Meldung passiert

Das gehört ausbuchstabiert, denn eine Meldung, die in einem Issue-Tracker verschwindet,
ist eine Meldung, die niemand ein zweites Mal schreibt.

**Du drückst *Hat bei mir funktioniert*.** Das Formular öffnet sich mit Seite,
Betriebssystem und heutigem Datum bereits darin. Eine Frage bleibt, und es ist die
einzige, die eine Maschine nicht beantworten kann: haben die Schritte *so wie geschrieben*
funktioniert, oder musstest du einen davon umgehen.

Wenn du ein Skript von der Seite ausgeführt hast, füllt `./scripts/<bereich>/verify.sh
--report` das Formular vollständiger aus, inklusive dessen, was das Skript beobachtet hat.
Es gibt einen Link aus und sendet nichts, du siehst also alles, bevor du dich fürs
Veröffentlichen entscheidest. Benutzernamen und Home-Pfade werden entfernt, bevor sie in
den Link gelangen.

**Ein Workflow liest sie.** Wenn du gemeldet hast, dass die Schritte wie geschrieben
funktioniert haben, öffnet er einen Pull Request, der der Seite eine Zeile hinzufügt:
dein Datum, unter dem Betriebssystem, auf dem du sie ausgeführt hast. Nichts von dem, was
du geschrieben hast, wird ins Repository kopiert: der Pull Request trägt ein Datum und
einen Link zurück zu deiner Meldung, und das ist alles.

Deshalb fragt das Formular nach dem System. Jede Seite hier gibt Arch, Debian und macOS
unterschiedliche Schritte. Ihr auf einem davon zu folgen, ist ein Beleg für dieses eine.
Dein Datum landet an diesem Block, und die anderen beiden bleiben genauso ungeprüft, wie
sie es waren.

**Ein Mensch merged ihn.** Das ist Absicht. Das Datum ist die einzige Behauptung dieses
Projekts, also stimmt ein Mensch ihm zu, bevor es veröffentlicht wird.

**Wenn die Schritte nicht wie geschrieben funktioniert haben**, wird kein Datum
hinzugefügt, und eines hinzuzufügen wäre unehrlich. Die Meldung wird stattdessen
etikettiert und bleibt als Aufgabe offen. Das ist die nützlichere der beiden Meldungen,
und aus ihr besteht der Abschnitt *Bekannte Eigenheiten* einer Seite.

**Nichts hiervon ist ein Versprechen.** Keine Reaktionszeit, keine Garantie, dass es
jemand aufgreift.

## Was jede Woche automatisch läuft

Einmal pro Woche laufen drei Prüfungen von selbst. Jede hält ein einzelnes Issue aktuell,
statt jedes Mal ein neues anzulegen, ein Wert, der seit einem Monat abweicht, ist also ein
Strang mit Verlauf.

- Die zentrale Aussage der VPN-Seite wird erneut gegen das Gateway geprüft, das öffentlich
  erreichbar ist. Liefert die THI irgendwann eine vollständige Zertifikatskette aus, sagt
  die Prüfung das, und die Seite wird einfacher.
- Jede in `facts/` notierte URL wird gefragt, ob sie noch antwortet. Anbieter verschieben
  Downloads, und keine Seitenbearbeitung würde das je zeigen.
- Seiten, die darauf warten, dass jemand ihnen folgt, werden zu einer Liste
  zusammengefasst.

Keine davon ändert jemals einen dokumentierten Wert. Ein beobachteter Wert ist kein
geprüfter, ein Unterschied wird also zu einem Issue, das ein Mensch liest, und nie zu
einer Änderung.

Prüfungen wird auch ihr Alter angesehen. Nach ${facts.project.stale_after_days} Tagen sagt
eine Seite weiterhin, wann sie geprüft wurde, und ergänzt, wie lange das her ist. Nichts
wird zurückgezogen und keine Seite als falsch markiert; dir wird schlicht gesagt, wie alt
die Aussage ist, und genau das brauchst du, um sie einzuschätzen.

Die vollständige Anleitung zum Beitragen steht in
[CONTRIBUTING.md](https://github.com/${facts.project.repo}/blob/main/.github/CONTRIBUTING.md)
(englisch).
