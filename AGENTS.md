# AGENTS.md

Machine-facing contract for this repository. Humans want `.github/CONTRIBUTING.md`.

This is a **public, unofficial** knowledge base of campus setup notes for Linux and
macOS. It is not a support channel and it speaks for nobody. Everything below follows
from that.

## Commands

```bash
npm install
npm run dev            # local preview on :5173
npm run build          # production build, fails on dead links
npm run check          # all CI checks; run before proposing a commit
npm run new-page       # scaffold a page with correct frontmatter
```

## Never

1. **Never commit personal data.** No usernames, no real names, no mail addresses, no
   `/home/<name>` paths, no inventory numbers, no log excerpts containing identifiers.
   Placeholders are `<kennung>`, `<vorname.nachname>`, `<hostname>`. `npm run check`
   enforces this; do not work around it.
2. **Never type a configuration value into a page.** Hostnames, queue names, ports,
   paths, CA names and URLs live in `facts/*.yaml` and are referenced as
   `${facts.<domain>.<key>}`. This is the single mechanism preventing the same value
   from drifting across pages, and it works inside code fences too.
3. **Never invent a fact.** If a value is unknown, say so on the page and open an issue.
   A plausible-looking hostname is worse than an admitted gap.
4. **Never auto-update trust material.** Certificate names, CA names and fingerprints
   are changed only by a human who confirmed them out of band. An observed value is not
   a verified value.
5. **Never claim verification you did not perform.** `status: checked` and `lastChecked`
   mean a person ran the steps on real hardware on that date.
6. **Never write a commitment.** No guarantees of accuracy, coverage, or response time.
   See "Voice" below.
7. **Never add a second tab axis.** Operating system is the only one. Terminal
   instructions go below the prose, never beside it as a tab.
8. **Never use an em dash (`—`) or en dash (`–`) as punctuation.** Not in prose, not in
   headings, not in frontmatter, not in comments, not in table cells. Use a comma, a
   colon, a semicolon, parentheses, or two sentences, whichever the sentence actually
   calls for. Do not swap one dash for another and do not substitute a hyphen for a
   dash. Hyphens stay where they belong: inside compound words such as `hole-punched`
   and inside identifiers such as `802-1x`. An en dash between two numbers is a range,
   not punctuation, and stays: `16–235`, `8–12 GB`, `R35–R40`. See "Voice" below for
   what to write instead.

## Page contract

Frontmatter:

```yaml
---
title: Short, searchable, in the reader's words
status: imported | structured | checked
lastChecked: 2026-08-07     # only meaningful with status: checked
os: [arch, debian, macos]   # which OS blocks this page provides
---
```

Body order, always:

1. What this page gets you, in one sentence.
2. The official channel, linked first.
3. Documented values, rendered from `facts/`.
4. The click-path in plain language, assuming no terminal.
5. The terminal fast path, per OS.
6. How to verify it worked.
7. Known quirks.

OS-specific content uses containers, never per-page forks:

````md
::: os arch
```bash
sudo pacman -S cups
```
:::
````

## Voice

Wording is a design constraint here, not a style preference. The project documents a
university's infrastructure without permission and without affiliation; language that
reads as a complaint or a claim of authority creates real problems.

| Do not write | Write |
|---|---|
| scan, probe, monitor | check documented endpoints |
| verified, guaranteed, certified | last checked on *date* |
| supported, official, approved | community-maintained |
| tested and working | reported working on *date* |
| IT broke X, outage | observed value differs from the documented value |
| ✅ / ❌ status seals | plain dates and words |
| an aside set off by `—` | an aside in parentheses, or its own sentence |
| `Step 1 — collect the values` | `Step 1: collect the values` |
| `—` as an empty table cell | `n/a`, or an empty cell |

Auto-generated issues and alerts are permanent and public. State what was observed, what
was documented, and when. Never attribute fault or intent to anyone.

## Languages

English is the source of truth. German pages under `content/de/` mirror the English path
exactly and carry `translatedFrom: <blob-sha>` pointing at the English source they were
made from. `npm run check` flags translations whose source has since changed.

German strings quoted from university systems (form labels, portal menu paths,
policy titles) stay verbatim in both languages, with a translation in parentheses on
English pages. A translated form label is an instruction the reader cannot follow.

## Scripts

Shell scripts are POSIX `sh` unless a page documents a bash-only step. They must be
sourceable without executing: define functions, guard the entry point, keep side effects
inside `main`. Every script supports `--dry-run` (print what would happen, change
nothing) and `--json` (machine-readable result, identifiers stripped).
