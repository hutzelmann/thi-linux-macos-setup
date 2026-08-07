# 0001: Project setup

Date: 2026-08-07 · Status: accepted

The decisions that shape the repository, and why. Requirements are in
`../requirements.md`; the framework evaluation is in `../stack-decision.md`.

## Name and hosting

`hutzelmann/thi-linux-macos-setup`, published at
`hutzelmann.github.io/thi-linux-macos-setup/`, public from the first commit.

The name carries the two words people actually search for (`linux`, `macos`) plus the
institution. "Unofficial" is deliberately *not* in the name: a name that leads with a
negation ages badly, and the tagline, the footer on every page and the issue routing all
carry that message where it is actually read.

Personal account rather than an organisation, chosen knowingly: the site outlives any
individual student, and the person maintaining it expects to be here for decades.

## Licence: CC0

Public domain, everything: prose, scripts and the facts data.

Attribution-required licences would block the best possible outcome, which is university
IT lifting a page into their own documentation. Two consequences follow and are handled:
`CONTRIBUTING.md` states that contributions are released under CC0, since a waiver cannot
be assumed from a pull request; and because nothing stops a stale mirror from
republishing, pages carry a visible last-checked date so a scraped copy carries its own
expiry.

## Content lives in `content/`, not `docs/`

The repository holds two kinds of documentation: the published knowledge base and the
repository's own (`README`, `CONTRIBUTING`, `design/`). Naming both "docs" is the
ambiguity. The folder name never appears in URLs.

## Facts are data, referenced by substitution

`facts/<domain>.yaml`, one file per service domain, substituted into pages at build time
as `${facts.domain.key}`, including inside code fences, which is where a stale hostname
does the most damage.

`scripts/ci/check-facts.sh` fails the build if a literal value from `facts/` appears in
page source. This converts R23 from a rule people remember into one the build enforces.
The motivating case is real: the print server was renamed, and every page that had typed
the name would have silently gone wrong.

One file per domain rather than one big file: it mirrors the check domains one-to-one, so
adding a service is one new file, and concurrent edits do not collide.

## Only four checks in CI, and no test harness yet

`shellcheck`, facts consistency, personal-data patterns, build with dead-link detection.
Plus a fifth, non-blocking, that asserts the VPN certificate chain still behaves as the
page describes.

Deliberately no unit or container tests yet. Most of what this project documents cannot be
tested without campus access, macOS cannot be containerised at all, and stubbing campus
services would mostly prove the stubs work. Writing scripts as sourceable functions with
`--dry-run` and `--json` keeps real tests cheap to add later, which is the part that
matters now.

## Issues only

No Discussions, no chat. The routing in `ISSUE_TEMPLATE/config.yml` therefore does real
work: blank issues are disabled and official support is linked first, so the tracker stays
about the pages rather than becoming a help desk the project cannot staff.

This makes a GitHub account the minimum barrier to contributing, which is a knowing
relaxation of R32; revisit if it turns out to exclude people who would otherwise
contribute.

## English is the source, German is translated

Mirrored paths (`/en/x` and `/de/x`), so the language switcher, the sidebar and the
staleness check are all a path swap.

Machine translation makes the first pass cheap and does nothing for the second month, so
every German page records the blob hash of the English source it came from and CI reports
when that source has moved on. A confidently wrong translation is worse than an English
page.

## One tab axis, forever

Operating system, and nothing else. A second dimension (terminal versus GUI) would mean
six variants of every snippet. Terminal instructions go below the plain-language ones on
the same page.

Visibility is CSS keyed off `html[data-os]`, set by a blocking script before first paint,
so there is no flash of the wrong OS and every variant stays indexable by search.
