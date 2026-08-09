# Linux and macOS at THI

Community setup notes for Linux and macOS at Technische Hochschule Ingolstadt: printing,
Wi-Fi, VPN, network shares.

**[Read the site →](https://hutzelmann.github.io/thi-linux-macos-setup/)**

> **Unofficial.** Not affiliated with, endorsed by, or speaking for university IT. No
> guarantees of any kind. For accounts, quotas and hardware use the official channels:
> [THI IT service](https://www.thi.de/service/it-service/),
> [knowledge base](https://help.thi.de/help/de-de), or write to support@thi.de.

## Why

Campus systems are documented for Windows. Most of it works on Linux and macOS too, but
the details (a driver path, a certificate authority, a hostname) are not written down
anywhere the next person can find them. This site writes them down.

Pages state when a human last checked them, and admit when nobody has.

## Contributing

Corrections are the most valuable contribution, and you do not need to clone anything.

| I want to… | Do this |
|---|---|
| Report something wrong | The *Something wrong here?* link at the bottom of any page |
| Say the steps worked | [File a check record](../../issues/new?template=check-record.yml) |
| Fix a typo or a sentence | *Edit this page on GitHub* at the bottom of the page |
| Write a new page | Read [CONTRIBUTING](.github/CONTRIBUTING.md), then `npm run new-page` |

Contributions are released into the public domain. Pseudonymous contributions are fine.

## Running it locally

```bash
npm install
npm run dev       # http://localhost:5173
npm run build     # production build; fails on dead links
npm run check     # everything CI checks
```

Node 22 or newer. For small edits press `.` on any file in GitHub for a browser editor.

## How it is organised

```
content/          the pages; content/en is the source, content/de is translated
facts/            hostnames, queue names, certificates: one file per service
scripts/          runnable setup and verification scripts, embedded into pages
design/           requirements and architecture decisions
```

Two rules explain most of the structure:

**A configuration value is written once.** It lives in `facts/` and pages reference it as
`${facts.printing.queue}`. CI fails if a page hardcodes one, because the next rename would
miss it.

**Scripts are real files, not code blocks.** Pages embed them from `scripts/`, so a
documented command and the runnable one cannot drift apart.

## Licence

[CC0 1.0](LICENSE), public domain. Copy it, fork it, paste it into official
documentation, no attribution required.
