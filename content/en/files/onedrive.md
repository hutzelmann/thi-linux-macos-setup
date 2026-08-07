---
title: OneDrive on Linux
description: What works and what does not for OneDrive sync on Linux at THI.
status: imported
os: [arch, debian, macos]
---

# OneDrive on Linux

There is no supported native OneDrive client for Linux. The browser interface works, and
so does the macOS client.

## The blocker for third-party clients

Applications that request access to the organisation's Microsoft 365 tenant need approval
from IT before they can authenticate. Open-source OneDrive clients fall into that
category.

Approval for [abraunegg/onedrive](https://abraunegg.github.io/) was requested in June
2025 and not granted. Without approval the client cannot complete sign-in — this is a
tenant policy, not a packaging problem, so no amount of local configuration works around
it.

## What works today

::: os arch

The web interface at [office.com](https://office.com). Files can be opened and edited in
the browser and downloaded individually.

:::

::: os debian

The web interface at [office.com](https://office.com). Files can be opened and edited in
the browser and downloaded individually.

:::

::: os macos

The official Microsoft OneDrive client works normally. Sign in with your campus account.

:::

For files that need to be on disk rather than in a browser tab,
[network shares](/en/shares/smb) are the supported alternative and need no third-party
software.

## Untested

[Insync](https://www.insynchq.com/) is a commercial client that may or may not be
affected by the same approval requirement. Nobody has tried it here. If you do, a
[check record](https://github.com/hutzelmann/thi-linux-macos-setup/issues/new?template=check-record.yml)
would close this gap.

---

::: info Imported notes
From personal notes, last touched in 2025. Tenant policies change; if a client works for
you now, please report it.
:::
