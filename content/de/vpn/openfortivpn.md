---
title: VPN von außerhalb des Campus mit openfortivpn
description: Mit openfortivpn und SSO-Anmeldung ins Campusnetz, ohne FortiClient, inklusive des Zertifikatsbündels, das die fehlende Kette ersetzt.
os: [arch, debian, macos]
lastChecked:
  arch: 2026-08-08
translatedFrom: 3885f0706a3caf70324a3229a3d3463040d2feba
---

# VPN von außerhalb des Campus

Bringt dich von überall ins Campusnetz, mit derselben SSO-Anmeldung wie überall sonst.
Nötig für [Netzlaufwerke](/de/shares/smb), manche Bibliotheksressourcen und alles, was prüft, ob du am
Campus bist.

Offizielle Dokumentation: [VPN-Service der THI](${facts.vpn.official_url}). Der offizielle
Client ist FortiClient; diese Seite nutzt `openfortivpn`: quelloffen, ohne Oberfläche und
ohne dauerhaft erhöhte Rechte außerhalb des Tunnels selbst.

## Das Zertifikatsproblem, einmalig

`${facts.vpn.host}` liefert das eigene Zertifikat aus, **aber nicht das
Zwischenzertifikat**, das es mit einer vertrauenswürdigen Wurzel verbindet. Ein korrekt
konfigurierter Client kann die Kette deshalb nicht vervollständigen und verweigert die
Verbindung. Das sieht wie ein Fehler auf dem eigenen Rechner aus, ist aber keiner.

Die Lösung: `openfortivpn` ein eigenes Zertifikatsbündel geben, bestehend aus dem
fehlenden Zwischenzertifikat und den Wurzelzertifikaten, die das System ohnehin
mitbringt. Mit `--ca-file` liest `openfortivpn` diese Datei statt des systemweiten
Zertifikatsspeichers. Ein Client lernt ein Gateway kennen, und sonst ändert sich auf dem
Rechner nichts daran, wem vertraut wird.

Das Zwischenzertifikat allein reicht nicht. Es ist nicht selbstsigniert, OpenSSL
akzeptiert es deshalb nicht als Anker und bricht mit „unable to get issuer certificate"
ab. Die Wurzeln gehören in dieselbe Datei.

::: os arch

```bash
sudo pacman -S openfortivpn
curl -o /tmp/inter.cer ${facts.vpn.intermediate_url}
openssl x509 -inform DER -in /tmp/inter.cer -out /tmp/${facts.vpn.intermediate_file}
sudo install -d -m 755 /etc/openfortivpn
cat /tmp/${facts.vpn.intermediate_file} ${facts.vpn.system_roots} |
  sudo tee ${facts.vpn.ca_bundle} > /dev/null
```

:::

::: os debian

```bash
sudo apt install openfortivpn
curl -o /tmp/inter.cer ${facts.vpn.intermediate_url}
openssl x509 -inform DER -in /tmp/inter.cer -out /tmp/${facts.vpn.intermediate_file}
sudo install -d -m 755 /etc/openfortivpn
cat /tmp/${facts.vpn.intermediate_file} ${facts.vpn.system_roots} |
  sudo tee ${facts.vpn.ca_bundle} > /dev/null
```

:::

::: os macos

macOS hält seine Wurzelzertifikate in einem Schlüsselbund statt in einer Datei, sie
werden deshalb zuerst exportiert.

```bash
brew install openfortivpn
curl -o /tmp/inter.cer ${facts.vpn.intermediate_url}
openssl x509 -inform DER -in /tmp/inter.cer -out /tmp/${facts.vpn.intermediate_file}
security find-certificate -a -p ${facts.vpn.macos_root_keychain} > /tmp/roots.pem
sudo install -d -m 755 /etc/openfortivpn
cat /tmp/${facts.vpn.intermediate_file} /tmp/roots.pem |
  sudo tee ${facts.vpn.ca_bundle} > /dev/null
```

:::

Die URL oben ist kein fremder Spiegel: Sie steht im Zertifikat des Gateways selbst, in der
Erweiterung „Authority Information Access". Das Zwischenzertifikat ist
`${facts.vpn.issuer}` unterhalb von `${facts.vpn.root_ca}`, dem dein System bereits
vertraut.

Das Bündel liegt bewusst unter `/etc` und gehört root. `openfortivpn` läuft mit `sudo`,
ein Bündel im Homeverzeichnis wäre also von genau dem Konto beschreibbar, das es schützen
soll.

## Verbinden

```bash
sudo openfortivpn ${facts.vpn.host} --saml-login --ca-file=${facts.vpn.ca_bundle}
```

openfortivpn gibt eine SSO-URL aus und wartet. Diese URL selbst im Browser öffnen und
wie gewohnt anmelden: geöffnet wird sie von niemandem, ein scheinbar hängender Aufruf
ist deshalb meist einer, dessen URL niemand angeklickt hat. Der Tunnel besteht, solange
der Befehl läuft; `Strg+C` trennt ihn.

Oder das Skript nutzen, das zuerst das Bündel prüft und den Fehler erklärt, statt einen
TLS-Fehler auszugeben:

<ScriptDownload file="vpn-connect.sh" does="Verbindet und erklärt verständlich, wenn das Bündel fehlt oder unvollständig ist" sudo />

::: tip Rückfallweg: das Zertifikat pinnen, für etwa ein Jahr
Wo sich kein Bündel bauen lässt, kann `openfortivpn` genau ein Gateway-Zertifikat
akzeptieren:

```bash
sudo openfortivpn ${facts.vpn.host} --saml-login --trusted-cert=<sha256>
```

`openfortivpn` gibt bei fehlgeschlagener Prüfung den zu übergebenden Digest selbst aus,
ein Fehlversuch genügt also. Vorab berechnen:

```bash
echo | openssl s_client -connect ${facts.vpn.host}:${facts.vpn.port} \
  -servername ${facts.vpn.host} 2>/dev/null |
  openssl x509 -noout -fingerprint -sha256 | cut -d= -f2 | tr -d ':' | tr 'A-Z' 'a-z'
```

Die Einschränkung: Gepinnt wird ein einzelnes Zertifikat, nicht die Kette, und das
Gateway-Zertifikat wird etwa jährlich ersetzt. Beim nächsten Wechsel schlägt die
Verbindung wieder fehl, und der Digest muss von Hand gesucht und neu eingetragen werden.
Das Bündel übersteht den Wechsel, weil Zwischen- und Wurzelzertifikat das Serverzertifikat
um Jahre überdauern.

Auf dieser Seite steht kein Digest. Ein aus dem Netz gelesener Wert ist ein beobachteter,
kein geprüfter Wert, und das Pinnen von Vertrauensmaterial entscheidet jede Leserin und
jeder Leser selbst.
:::

## Prüfen

<ScriptDownload file="vpn-verify.sh" does="Prüft das Gateway und ob das dokumentierte Bündel vorhanden ist" />

Es wird nichts verbunden und keine Zugangsdaten verwendet; geprüft wird nur der
TLS-Handshake. Von Hand:

```bash
echo | openssl s_client -connect ${facts.vpn.host}:${facts.vpn.port} \
  -servername ${facts.vpn.host} 2>/dev/null | openssl x509 -noout -subject -dates
```

## Bekannte Eigenheiten

::: os arch

**DNS stört Avahi, und Avahi bricht das Drucken.** `openfortivpn` stellt DNS über
`resolvconf` um. Auf Systemen mit `systemd-resolved` kollidiert das mit dem
Avahi-Dienst, den CUPS für die Druckererkennung braucht. Eine VPN-Verbindung kann das
Drucken also lahmlegen, bis sie getrennt wird. Üblicher Ausweg: `openresolv`
installieren und die Umstellung darüber laufen lassen. Diskussion:
[Arch-BBS-Thread](https://bbs.archlinux.org/viewtopic.php?id=288227).

**`openresolv` zu installieren ist nur die halbe Miete, und die andere Hälfte meldet sich
leise.** Das Gateway schiebt seine Nameserver und ein Suffix nach, `openfortivpn` reicht
beides an `resolvconf` weiter. Schreibt NetworkManager `/etc/resolv.conf` weiterhin
selbst, beanspruchen zwei Programme dieselbe Datei: `openresolv` findet eine Datei, die
es nicht angelegt hat, und lehnt ab, statt sie zu überschreiben.

```
INFO:   Adding VPN nameservers...
resolvconf: signature mismatch: /etc/resolv.conf
resolvconf: run `resolvconf -u` to update
```

Der Verkehr durch den Tunnel ist davon unberührt, es wirkt also wie ein verbundenes VPN,
in dem plötzlich kein einziger Campusname mehr bekannt ist, und in `/etc/resolv.conf`
steht weiterhin das, was das lokale Netz geliefert hat. Die erste Zeile dieser Datei
nennt das Programm, das sie zuletzt geschrieben hat, und trennt die beiden Fälle am
schnellsten. Welche Nameserver hätten gesetzt werden sollen, gibt `openfortivpn` eine
Zeile darüber selbst aus, in der Zeile `Got addresses`.

Das ist eine lokale Kollision und hat mit dem Campus nichts zu tun. Ein Lösungsweg ist
hier noch nicht festgehalten.

:::

::: os debian

**DNS stört Avahi, und Avahi bricht das Drucken.** `openfortivpn` stellt DNS über
`resolvconf` um. Auf Systemen mit `systemd-resolved` kollidiert das mit dem
Avahi-Dienst, den CUPS für die Druckererkennung braucht. Eine VPN-Verbindung kann das
Drucken also lahmlegen, bis sie getrennt wird. Üblicher Ausweg: `openresolv`
installieren und die Umstellung darüber laufen lassen. Diskussion:
[Arch-BBS-Thread](https://bbs.archlinux.org/viewtopic.php?id=288227).

**`openresolv` zu installieren ist nur die halbe Miete, und die andere Hälfte meldet sich
leise.** Das Gateway schiebt seine Nameserver und ein Suffix nach, `openfortivpn` reicht
beides an `resolvconf` weiter. Schreibt NetworkManager `/etc/resolv.conf` weiterhin
selbst, beanspruchen zwei Programme dieselbe Datei: `openresolv` findet eine Datei, die
es nicht angelegt hat, und lehnt ab, statt sie zu überschreiben.

```
INFO:   Adding VPN nameservers...
resolvconf: signature mismatch: /etc/resolv.conf
resolvconf: run `resolvconf -u` to update
```

Der Verkehr durch den Tunnel ist davon unberührt, es wirkt also wie ein verbundenes VPN,
in dem plötzlich kein einziger Campusname mehr bekannt ist, und in `/etc/resolv.conf`
steht weiterhin das, was das lokale Netz geliefert hat. Die erste Zeile dieser Datei
nennt das Programm, das sie zuletzt geschrieben hat, und trennt die beiden Fälle am
schnellsten. Welche Nameserver hätten gesetzt werden sollen, gibt `openfortivpn` eine
Zeile darüber selbst aus, in der Zeile `Got addresses`.

Das ist eine lokale Kollision und hat mit dem Campus nichts zu tun. Ein Lösungsweg ist
hier noch nicht festgehalten.

:::

**`--saml-login` braucht einen Browser auf demselben Rechner.** Auf einem Server ohne
Oberfläche musst du dich anderswo anmelden und das Cookie übergeben.

**Wie viel Verkehr durch den Tunnel läuft, entscheidet das Gateway, nicht eine
Einstellung hier.** Auf einem Konto hat das Gateway ausschließlich Routen in die
Campusnetze gesetzt, die Standardroute blieb auf der lokalen Schnittstelle, Verkehr zu
allem anderen lief also nicht durch den Tunnel. Das ist eine Richtlinie auf
Gateway-Seite und kann sich je nach Konto unterscheiden. Deshalb an der eigenen
Verbindung ablesen, statt es in die eine oder andere Richtung anzunehmen:

```bash
ip route show dev ppp0     # was das Gateway in den Tunnel geroutet hat
ip route show default      # unverändert heißt: alles andere bleibt lokal
```
