---
title: OneDrive and Microsoft 365 files
description: What works for OneDrive on Linux, why third-party clients cannot sign in, and what to use instead.
status: structured
os: [arch, debian, macos]
---

# OneDrive and Microsoft 365 files

Short version: **the browser works everywhere, the native client works only on macOS, and
third-party Linux clients cannot sign in at all.** The reason is a tenant policy rather
than a packaging problem, so it is worth understanding before spending an evening on it.

Official documentation: [${facts.official.department}](${facts.official.service_url}).

## Why Linux clients fail

Applications that want access to the university's Microsoft 365 tenant must be approved by
IT before they can complete sign-in. Open-source OneDrive clients register as exactly such
an application.

Approval for [abraunegg/onedrive](https://abraunegg.github.io/) was requested in June 2025
and not granted. Until that changes, the client gets as far as the login screen and then
fails. No local configuration can work around a decision made on the server.

Worth knowing so you can recognise the symptom: a sign-in that ends with a message about
needing administrator approval is this, not a broken installation.

## What works

::: os arch

**The web interface** at [office.com](https://office.com). Open, edit and download
individual files. Nothing to install.

For files that need to exist on disk (a build, a script, a backup),
[network shares](/en/shares/smb) are the supported route and need no third-party
software.

:::

::: os debian

**The web interface** at [office.com](https://office.com). Open, edit and download
individual files. Nothing to install.

For files that need to exist on disk (a build, a script, a backup),
[network shares](/en/shares/smb) are the supported route and need no third-party
software.

:::

::: os macos

**The official Microsoft OneDrive client** works normally. Install it, sign in with your
campus account, done. The tenant approves Microsoft's own client.

:::

## Verify

There is nothing to check on the machine; the question is whether the tenant policy has
changed. Try signing in with the client you want and watch for an approval message.

If a client that previously failed now works, that is a real finding. Please
[report it](https://github.com/hutzelmann/thi-linux-macos-setup/issues/new?template=check-record.yml),
because this page currently tells people not to bother.

## Known quirks

**Nobody has tried [Insync](https://www.insynchq.com/) here.** It is commercial and may
or may not hit the same approval requirement. Untested, so this page cannot say.

**Requesting approval is a legitimate route.** If enough people ask IT for a specific
client, the answer can change. That request goes to ${facts.official.support_mail}, not to
this project.
