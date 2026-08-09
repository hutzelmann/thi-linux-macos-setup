# AGENTS.md

Machine-facing contract for this repository. Humans want `.github/CONTRIBUTING.md`.

This is a **public, unofficial** knowledge base of campus setup notes for Linux and
macOS. It is not a support channel and it speaks for nobody. Everything below follows
from that.

## Commands

```bash
npm install
npm run dev            # local preview on :5173
npm run preview        # serve the production build, after npm run build
npm run build          # production build, fails on dead links
npm run check          # all CI checks; run before proposing a commit
npm run new-page       # scaffold a page with correct frontmatter
npm run record -- /en/printing/   # record a check you just performed
npm run check:drift    # the three checks the weekly workflow runs
npm run test:printing  # the print queue scripts, in throwaway containers
```

## Never

These nine are cited elsewhere in full, as `AGENTS.md rule 9`. `R<n>` belongs to
`design/requirements.md` and refers to nothing here.

1. **Never commit personal data.** No usernames, no real names, no mail addresses, no
   `/home/<name>` paths, no inventory numbers, no log excerpts containing identifiers.
   Placeholders are `<kennung>`, `<vorname.nachname>`, `<hostname>`. `npm run check`
   enforces this; do not work around it.
2. **Never type a configuration value into a page.** Hostnames, queue names, ports,
   paths, CA names and URLs live in `facts/*.yaml` and are referenced as
   `${facts.<domain>.<key>}`. This is the single mechanism preventing the same value
   from drifting across pages, and it works inside code fences too. Values about the
   repository itself, the GitHub slug and the staleness horizon, live in
   `facts/project.yaml` and are read the same way, so a shell script, a Node tool and the
   site cannot disagree about them.
3. **Never invent a fact.** If a value is unknown, say so on the page and open an issue.
   A plausible-looking hostname is worse than an admitted gap.
4. **Never auto-update trust material.** Certificate names, CA names and fingerprints
   are changed only by a human who confirmed them out of band. An observed value is not
   a verified value.
5. **Never claim verification you did not perform.** A `lastChecked` entry means a
   person ran that operating system's steps on real hardware on that date. Add it for
   your own run, or from a check record filed by the person who ran them, and never from
   hearsay. Never move an existing date forward to look current, and never copy one
   across operating systems: a run on Arch is evidence about the Arch block only. The
   check-record workflow is the one automated route that may add a date, and it adds
   nothing else. If you are an agent, you may run `npm run record` and you may not answer
   its questions. Whether the steps worked is an observation about a machine you did not
   touch, and the prompt exists to be answered by the person who did.
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
9. **Never leave a page in one language.** Every page under `content/en/` has a
   counterpart at the same path under `content/de/`, and every edit to an English page is
   mirrored into the German one in the same commit, with `translatedFrom` set to the new
   blob hash. A page that exists in one language sends every reader who switches language
   to a 404, and the two sidebars stop being the same tree. `npm run check` enforces both
   halves; `npm run new-page` creates the pair. See "Languages" below.

## Where writing goes

| What | Where |
|---|---|
| A page for readers | `content/en/<path>.md`, and its German mirror at the same path |
| How this repository works, as a contract | this file |
| How to contribute, for humans | `.github/CONTRIBUTING.md` |
| Why something was decided, and what was rejected | `design/decisions/NNNN-*.md` |
| What the project is trying to be | `design/requirements.md` |

Never create a second documentation directory. `content/` is the published knowledge base
and `design/` is the repository's own reasoning, which is the whole reason neither is
called `docs/`. A `docs/` alongside them was tried: it produced two files that contradicted
`design/decisions/0001-project-setup.md`, described shipped work as pending, and carried
session scaffolding that meant nothing once the work landed.

Decision records are written in the past tense, after the work lands, and are not edited
afterwards. A decision that changes gets a new record which supersedes the old one, so that
a dated statement about the past can never fall out of step with the present. A plan for
work that has not happened is an issue, not a record. `design/README.md` has the full rule.

`R<n>` cites `design/requirements.md`. The nine rules above are cited in full, as
`AGENTS.md rule 9`.

## Committing

`git commit` commits the index, not the files you just edited. Stage the paths you mean,
run `git status` before every commit, and read what is staged instead of assuming it.

Never run `git reset --hard`, `git checkout -- .` or `git clean` while uncommitted work is
present. Recovering the last such incident here took a full session, and it only worked
because a production build made from the intact tree happened to still exist. When a
working tree has to be set aside, `git stash` keeps it.

Commit messages follow the voice rules, rule 8 included. No em dashes.

## Page contract

Frontmatter:

```yaml
---
title: Short, searchable, in the reader's words
description:                # optional; one sentence, for search and link previews
lastChecked:                # omit entirely until somebody ran the steps
  arch: 2026-08-07          # one date per OS, never one date for the page
os: [arch, debian, macos]   # which OS blocks this page provides
---
```

`check-facts.sh` greps the whole markdown file, frontmatter included, so a documented
value typed into `description` fails exactly as it would in the body. It scans
`content/**/*.md` and nothing else: the same value typed into a script, a tool or a design
record is not caught, which is why rule 2 is a rule and not only a check.

There is no `status` field. A page is checked, for one operating system, exactly when it
carries a date for it, so the state and its date cannot contradict each other and
"checked" cannot be claimed without saying when. Pages that declare `os` carry the
marker. Pages without steps to run on a machine say `nothing to check here` in grey
rather than dropping the line, so the heading does not move as the reader navigates.

`lastChecked` is a map keyed by the operating system the run happened on, and the keys
are a subset of `os`. Every page forks its steps three ways, so a single date would claim
two checks nobody performed. The marker follows the reader's selected OS: switching from
Arch to macOS changes the steps and changes the marker with them. A date for an OS the
page does not declare is refused, because there are no steps there to have followed.

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

Every page exists in both languages. English is the source of truth; German pages under
`content/de/` mirror the English path exactly and carry `translatedFrom: <blob-sha>`
pointing at the English source they were made from.

Changing an English page is therefore two edits, not one:

1. Edit `content/en/<path>.md`.
2. Mirror the change into `content/de/<path>.md`, in the same commit, and set
   `translatedFrom` to `git hash-object content/en/<path>.md` as it now stands.

`npm run check` fails on either half being missing: an English page with no German
counterpart (and the reverse), and a German page whose recorded hash no longer matches
its source. The failure message prints the hash to write. Creating a page is
`npm run new-page`, which writes both files and both sidebar entries, so the pair is
never broken in the first place.

The reason is navigational, not editorial. The language switcher, the two sidebars and
the `hreflang` pairs all work by swapping one path segment, so a page that exists in one
language is a 404 for every reader who switches on it, and a sidebar that hides what the
other one offers. Both sidebars in `content/.vitepress/sidebar.mts` therefore carry the
same entries in the same order.

Translating a long page in one go is not required, but shipping the English edit without
the German one is: a German stub that says what it is beats a missing file, because the
reader still lands somewhere and the check still passes.

German strings quoted from university systems (form labels, portal menu paths,
policy titles) stay verbatim in both languages, with a translation in parentheses on
English pages. A translated form label is an instruction the reader cannot follow.

## Recording a check

`lastChecked` is written by `tools/check-record.mjs` and never by hand. Three front ends
call it, so they cannot drift apart:

| Route | Who | What confirms it |
|---|---|---|
| `.github/workflows/check-record.yml` | anyone, through the issue form | a maintainer merges the pull request |
| `npm run record -- /en/printing/` | a maintainer with the hardware | two prompts on the terminal |
| `node tools/check-record.mjs --issue=N` | a maintainer, from a filed issue | the diff, before it is written |

Only the outcome `Worked exactly as written` may write a date.

A record names one operating system and writes one entry. The form's `What did you run it
on` dropdown is what decides which, `npm run record` defaults to the machine it is running
on (`--os=` overrides), and both accept the bare ids `verify.sh --json` prints. `Other
Linux` records nothing: the pages have no block for it, so there are no steps a date could
refer to. Neither does an OS the page does not declare.

A record covers both language versions of a page, since both take their values from the
same `facts/` entries and are followed with the same script. That carries across only
while `check-translations.sh` passes for the pair; when the translation is already out of
date the check stops at the page it was filed against. It never carries across operating
systems: both languages describe the same three blocks, and running one of them is
evidence about that one.

## Scripts

Shell scripts are POSIX `sh` unless a page documents a bash-only step. They must be
sourceable without executing: define functions, guard the entry point, keep side effects
inside `main`. Every script supports `--dry-run` (print what would happen, change
nothing) and `--json` (machine-readable result, identifiers stripped). Every `verify.sh`
also supports `--report`, which prints a prefilled check-record link and declares the
page it belongs to as `REPORT_PAGE`.

Scripts never hardcode a value: they call `fact <domain> <key>`, which reads `facts/`.
Any single value can be replaced for one run by setting `FACT_<DOMAIN>_<KEY>` in the
environment, uppercased, so a check can point at a scratch path or a local stand-in
without editing `facts/` and without changing the machine it runs on:

```sh
FACT_VPN_CA_BUNDLE=/tmp/bundle.pem scripts/vpn/verify.sh
```

Every override is named in the result, as `facts_overridden` in `--json` and as a
paragraph under `--report`, and an overridden run never prefills a check-record outcome.
A pass against a substituted value observed something real, but it did not observe what
the page documents, and the two must not be able to look alike (rule 5).

## Running the scripts without a campus

`test/printing/` builds two throwaway containers, Arch and Debian, and runs
`printing/install.sh` and `printing/verify.sh` in them unmodified. Everything the install
script does is a change to CUPS on the machine that runs it, so this is the only way to
exercise it without either changing a working machine or not exercising it at all.

Two images because the page gives the two systems different instructions: Debian installs
a `.deb` and points `lpadmin` at an absolute PPD path, Arch builds
`${facts.printing.driver_aur}` from the AUR and points it at a CUPS model name. Each
image asserts what its own block of the page claims, so a pass on one says nothing about
the other.

```bash
npm run test:printing                             # both, no driver
bash test/printing/run.sh --os=arch --build-aur   # Arch, building from the AUR
bash test/printing/run.sh --os=debian --driver-deb=<deb>
```

The driver is optional and worth supplying: it is what makes `ppd_path`, `ppd_model` and
the finishing options checkable at all. Without it the suite runs the dry-run, samba and
failure-path assertions and skips the rest, saying so.

What no container answers: whether the print server accepts the job, whether SMB
authentication works, whether the sheet comes out punched. A green suite is not a check
record and must never be recorded as one.
