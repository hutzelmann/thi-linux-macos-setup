---
title: VPN from Linux and macOS
description: Connect to the campus VPN with openfortivpn and SSO login. Includes the certificate-chain fix the gateway needs.
status: structured
os: [arch, debian, macos]
---

# VPN from Linux and macOS

Gets you onto the campus network from anywhere, using the same SSO login as everything
else. Needed for network shares, some library resources, and anything that checks
whether you are on campus.

Official documentation: [THI VPN service](${facts.vpn.official_url}). The official
client is FortiClient; this page uses `openfortivpn`, which is open source, has no GUI
and does not need to be installed with administrator rights beyond the tunnel itself.

## The certificate problem, once

`${facts.vpn.host}` presents its own certificate but **does not send the intermediate
certificate** that links it to a trusted root. A correctly configured client therefore
cannot build a complete chain and refuses to connect — which looks like a client bug and
is not one.

The fix is to supply the missing intermediate once. After that, everything works with no
special flags and nothing to maintain.

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

The URL above is not a third-party mirror: it is published inside the gateway's own
certificate, in the Authority Information Access extension. The intermediate is
`${facts.vpn.issuer}`, under `${facts.vpn.root_ca}`, which your system already trusts.

::: tip Why no fingerprint
Older notes pin the gateway's certificate fingerprint with `--trusted-cert`. That works,
but the certificate is replaced roughly every year, and each replacement means finding
and re-recording trust material by hand. Fixing the chain instead is permanent: the root
runs to 2045.
:::

## Connect

```bash
sudo openfortivpn ${facts.vpn.host} --saml-login
```

A browser window opens for the usual SSO login. The tunnel stays up as long as the
command runs; `Ctrl+C` disconnects.

Or use the script, which checks the chain first and explains the failure instead of
printing a TLS error:

<ScriptDownload file="vpn-connect.sh" does="Connects, with a readable diagnosis if the chain is incomplete" sudo />

## Verify

<ScriptDownload file="vpn-verify.sh" does="Checks the gateway and whether the documented chain fix is in place" />

Nothing is connected and no credentials are used — it observes the TLS handshake only.
By hand:

```bash
echo | openssl s_client -connect ${facts.vpn.host}:${facts.vpn.port} \
  -servername ${facts.vpn.host} 2>/dev/null | openssl x509 -noout -subject -dates
```

## Known quirks

**DNS breaks Avahi, and Avahi breaks printing.** `openfortivpn` reconfigures DNS through
`resolvconf`. On systems using `systemd-resolved`, this collides with the Avahi daemon
that CUPS relies on for printer discovery — so connecting to the VPN can stop printing
from working until you disconnect. Installing `openresolv` and letting it manage the
handover is the usual fix. Discussion:
[Arch BBS thread](https://bbs.archlinux.org/viewtopic.php?id=288227).

**`--saml-login` needs a browser on the same machine.** On a headless box, authenticate
elsewhere and pass the resulting cookie, or use a different approach entirely.

**No split tunnelling by default.** All traffic goes through campus while connected.
Expected, but worth knowing before a large download.
