---
title: VPN from off campus with openfortivpn
description: Connect to the campus VPN with openfortivpn and SSO login, without FortiClient. Includes the certificate bundle the gateway needs.
os: [arch, debian, macos]
lastChecked:
  arch: 2026-08-08
---

# VPN from off campus

Gets you onto the campus network from anywhere, using the same SSO login as everything
else. Needed for [network shares](/en/shares/smb), some library resources, and anything that checks
whether you are on campus.

Official documentation: [THI VPN service](${facts.vpn.official_url}). The official
client is FortiClient; this page uses `openfortivpn`, which is open source, has no GUI
and does not need to be installed with administrator rights beyond the tunnel itself.

## The certificate problem, once

`${facts.vpn.host}` presents its own certificate but **does not send the intermediate
certificate** that links it to a trusted root. A correctly configured client therefore
cannot build a complete chain and refuses to connect, which looks like a client bug and
is not one.

The fix is to give `openfortivpn` its own certificate bundle: the missing intermediate,
followed by the root certificates the system already ships. `--ca-file` makes
`openfortivpn` read that file instead of the system trust store, so one client learns
about one gateway and nothing else on the machine changes what it trusts.

The intermediate on its own is not enough. It is not self-signed, so OpenSSL will not
accept it as an anchor and stops at "unable to get issuer certificate". The roots belong
in the same file.

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

macOS keeps its roots in a keychain rather than a file, so they are exported first.

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

The URL above is not a third-party mirror: it is published inside the gateway's own
certificate, in the Authority Information Access extension. The intermediate is
`${facts.vpn.issuer}`, under `${facts.vpn.root_ca}`, which your system already trusts.

The bundle lives under `/etc` and is owned by root on purpose. `openfortivpn` runs with
`sudo`, so a bundle in a home directory would be writable by the account it is meant to
protect.

## Connect

```bash
sudo openfortivpn ${facts.vpn.host} --saml-login --ca-file=${facts.vpn.ca_bundle}
```

openfortivpn prints an SSO URL and waits. Open that URL in a browser yourself and log
in as usual: nothing opens it for you, so a run that looks stuck is usually a run whose
URL nobody clicked. The tunnel stays up as long as the command runs; `Ctrl+C`
disconnects.

Or use the script, which checks the bundle first and explains the failure instead of
printing a TLS error:

<ScriptDownload file="vpn-connect.sh" does="Connects, with a readable diagnosis if the bundle is missing or incomplete" sudo />

::: tip Fallback: pin the certificate, for about a year
Where building a bundle is not an option, `openfortivpn` can be told to accept one
specific gateway certificate:

```bash
sudo openfortivpn ${facts.vpn.host} --saml-login --trusted-cert=<sha256>
```

`openfortivpn` prints the exact digest to pass when validation fails, so one failed
attempt is enough to read it. To work it out beforehand:

```bash
echo | openssl s_client -connect ${facts.vpn.host}:${facts.vpn.port} \
  -servername ${facts.vpn.host} 2>/dev/null |
  openssl x509 -noout -fingerprint -sha256 | cut -d= -f2 | tr -d ':' | tr 'A-Z' 'a-z'
```

The limitation: this pins a single certificate rather than the chain, and the gateway
certificate is replaced roughly once a year. On the next replacement the connection
fails again and the digest has to be found and re-recorded by hand. The bundle above
survives that, because the intermediate and the root outlive the leaf by years.

No digest is recorded on this page. A value read off the network is an observed value,
not a verified one, and pinning trust material is a decision each reader makes for
themselves.
:::

## Verify

<ScriptDownload file="vpn-verify.sh" does="Checks the gateway and whether the documented bundle is in place" />

Nothing is connected and no credentials are used; it observes the TLS handshake only.
By hand:

```bash
echo | openssl s_client -connect ${facts.vpn.host}:${facts.vpn.port} \
  -servername ${facts.vpn.host} 2>/dev/null | openssl x509 -noout -subject -dates
```

## Known quirks

::: os arch

**DNS breaks Avahi, and Avahi breaks printing.** `openfortivpn` reconfigures DNS through
`resolvconf`. On systems using `systemd-resolved`, this collides with the Avahi daemon
that CUPS relies on for printer discovery, so connecting to the VPN can stop printing
from working until you disconnect. Installing `openresolv` and letting it manage the
handover is the usual fix. Discussion:
[Arch BBS thread](https://bbs.archlinux.org/viewtopic.php?id=288227).

**Installing `openresolv` is only half of it, and the other half is quiet.** The gateway
pushes its nameservers and a search suffix, and `openfortivpn` hands them to
`resolvconf`. If NetworkManager is still writing `/etc/resolv.conf` itself, two programs
claim one file: `openresolv` finds a file it did not create and declines rather than
overwrite it.

```
INFO:   Adding VPN nameservers...
resolvconf: signature mismatch: /etc/resolv.conf
resolvconf: run `resolvconf -u` to update
```

Traffic through the tunnel is unaffected, so this presents as a connected VPN in which
every campus name has suddenly become unknown, and `/etc/resolv.conf` still lists
whatever your local network gave you. The first line of that file names whichever
program last wrote it, which is the quickest way to tell the two situations apart. The
nameservers that should have been installed are printed by `openfortivpn` itself, one
line above, in its `Got addresses` line.

This is a local collision rather than anything about campus. No fix is recorded here
yet.

:::

::: os debian

**DNS breaks Avahi, and Avahi breaks printing.** `openfortivpn` reconfigures DNS through
`resolvconf`. On systems using `systemd-resolved`, this collides with the Avahi daemon
that CUPS relies on for printer discovery, so connecting to the VPN can stop printing
from working until you disconnect. Installing `openresolv` and letting it manage the
handover is the usual fix. Discussion:
[Arch BBS thread](https://bbs.archlinux.org/viewtopic.php?id=288227).

**Installing `openresolv` is only half of it, and the other half is quiet.** The gateway
pushes its nameservers and a search suffix, and `openfortivpn` hands them to
`resolvconf`. If NetworkManager is still writing `/etc/resolv.conf` itself, two programs
claim one file: `openresolv` finds a file it did not create and declines rather than
overwrite it.

```
INFO:   Adding VPN nameservers...
resolvconf: signature mismatch: /etc/resolv.conf
resolvconf: run `resolvconf -u` to update
```

Traffic through the tunnel is unaffected, so this presents as a connected VPN in which
every campus name has suddenly become unknown, and `/etc/resolv.conf` still lists
whatever your local network gave you. The first line of that file names whichever
program last wrote it, which is the quickest way to tell the two situations apart. The
nameservers that should have been installed are printed by `openfortivpn` itself, one
line above, in its `Got addresses` line.

This is a local collision rather than anything about campus. No fix is recorded here
yet.

:::

**`--saml-login` needs a browser on the same machine.** On a headless box, authenticate
elsewhere and pass the resulting cookie, or use a different approach entirely.

**How much traffic goes through the tunnel is the gateway's decision, not a setting
here.** On one account the gateway pushed routes for the campus networks only,
and the default route stayed on the local interface, so traffic to anywhere else did not
enter the tunnel. This is a policy on the gateway side and can differ per account, so
read it off your own connection rather than assuming either way:

```bash
ip route show dev ppp0     # what the gateway routed into the tunnel
ip route show default      # unchanged means everything else stays local
```
Expected, but worth knowing before a large download.
