---
title: VPN unter Linux und macOS
description: Mit openfortivpn und SSO-Anmeldung ins Campusnetz, inklusive der Zertifikatskette, die das Gateway nicht mitliefert.
status: structured
os: [arch, debian, macos]
translatedFrom: 83435f26e778087a7ff1932e8d0133cd612dc556
---

# VPN unter Linux und macOS

Bringt dich von überall ins Campusnetz, mit derselben SSO-Anmeldung wie überall sonst.
Nötig für Netzlaufwerke, manche Bibliotheksressourcen und alles, was prüft, ob du am
Campus bist.

Offizielle Dokumentation: [VPN-Service der THI](${facts.vpn.official_url}). Der offizielle
Client ist FortiClient; diese Seite nutzt `openfortivpn` — quelloffen, ohne Oberfläche und
ohne dauerhaft erhöhte Rechte außerhalb des Tunnels selbst.

## Das Zertifikatsproblem, einmalig

`${facts.vpn.host}` liefert das eigene Zertifikat aus, **aber nicht das
Zwischenzertifikat**, das es mit einer vertrauenswürdigen Wurzel verbindet. Ein korrekt
konfigurierter Client kann die Kette deshalb nicht vervollständigen und verweigert die
Verbindung — das sieht wie ein Fehler auf dem eigenen Rechner aus, ist aber keiner.

Die Lösung: das fehlende Zwischenzertifikat einmal nachinstallieren. Danach funktioniert
alles ohne Sonderoptionen, und es gibt nichts zu pflegen.

::: os arch

```bash
sudo pacman -S openfortivpn
curl -o /tmp/inter.cer ${facts.vpn.intermediate_url}
openssl x509 -inform DER -in /tmp/inter.cer -out /tmp/${facts.vpn.intermediate_file}
sudo trust anchor --store /tmp/${facts.vpn.intermediate_file}
```

:::

::: os debian

```bash
sudo apt install openfortivpn
curl -o /tmp/inter.cer ${facts.vpn.intermediate_url}
openssl x509 -inform DER -in /tmp/inter.cer -out /tmp/${facts.vpn.intermediate_file}
sudo cp /tmp/${facts.vpn.intermediate_file} /usr/local/share/ca-certificates/${facts.vpn.intermediate_file}.crt
sudo update-ca-certificates
```

:::

::: os macos

```bash
brew install openfortivpn
curl -o /tmp/inter.cer ${facts.vpn.intermediate_url}
openssl x509 -inform DER -in /tmp/inter.cer -out /tmp/${facts.vpn.intermediate_file}
sudo security add-trusted-cert -d -k /Library/Keychains/System.keychain \
  /tmp/${facts.vpn.intermediate_file}
```

:::

Die URL oben ist kein fremder Spiegel: Sie steht im Zertifikat des Gateways selbst, in der
Erweiterung „Authority Information Access". Das Zwischenzertifikat ist
`${facts.vpn.issuer}` unterhalb von `${facts.vpn.root_ca}`, dem dein System bereits
vertraut.

::: tip Warum kein Fingerprint
Ältere Anleitungen pinnen den Fingerprint des Gateways per `--trusted-cert`. Das
funktioniert, aber das Zertifikat wird etwa jährlich ersetzt, und jedes Mal muss
Vertrauensmaterial von Hand gesucht und neu eingetragen werden. Die Kette zu reparieren
ist dauerhaft: Die Wurzel läuft bis 2045.
:::

## Verbinden

```bash
sudo openfortivpn ${facts.vpn.host} --saml-login
```

Es öffnet sich ein Browserfenster mit der gewohnten SSO-Anmeldung. Der Tunnel besteht,
solange der Befehl läuft; `Strg+C` trennt ihn.

Oder das Skript nutzen, das zuerst die Kette prüft und den Fehler erklärt, statt einen
TLS-Fehler auszugeben:

```bash
./scripts/vpn/connect.sh --dry-run   # nur anzeigen
./scripts/vpn/connect.sh
```

<<< @/../scripts/vpn/connect.sh{sh}

## Prüfen

```bash
./scripts/vpn/verify.sh          # lesbar
./scripts/vpn/verify.sh --json   # für eine Fehlermeldung
```

Ohne Skript, die Kette von Hand:

```bash
echo | openssl s_client -connect ${facts.vpn.host}:${facts.vpn.port} \
  -servername ${facts.vpn.host} 2>/dev/null | openssl x509 -noout -subject -dates
```

## Bekannte Eigenheiten

**DNS stört Avahi, und Avahi bricht das Drucken.** `openfortivpn` stellt DNS über
`resolvconf` um. Auf Systemen mit `systemd-resolved` kollidiert das mit dem
Avahi-Dienst, den CUPS für die Druckererkennung braucht — eine VPN-Verbindung kann das
Drucken also lahmlegen, bis sie getrennt wird. Üblicher Ausweg: `openresolv`
installieren und die Umstellung darüber laufen lassen. Diskussion:
[Arch-BBS-Thread](https://bbs.archlinux.org/viewtopic.php?id=288227).

**`--saml-login` braucht einen Browser auf demselben Rechner.** Auf einem Server ohne
Oberfläche musst du dich anderswo anmelden und das Cookie übergeben.

**Kein Split-Tunneling.** Während der Verbindung läuft der gesamte Verkehr über den
Campus. Erwartbar, aber gut zu wissen, bevor ein großer Download startet.
