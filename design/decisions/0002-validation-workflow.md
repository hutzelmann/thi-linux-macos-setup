# 0002: Validation workflow

Date: 2026-08-07 · Status: accepted · Landed: 2026-08-09

How a person following a page on real hardware turns into a `lastChecked` date, and what
is allowed to write one. Builds on the page contract in `0001`; the enforced form of the
rules below is in `AGENTS.md`.

## The problem: evidence never became a claim

A page claims a check by carrying `lastChecked`. Before this, nothing in the repository
turned evidence into that claim. Three symptoms, all of them dead ends:

1. `.github/ISSUE_TEMPLATE/check-record.yml` collected a report and no code read it.
2. `scripts/<area>/verify.sh --json` produced machine-readable evidence that died in the
   contributor's terminal.
3. `content/en/about/how-this-works.md` told the reader to "say so" without saying how, or
   what happened next.

The layer this sits on: `npm run check` and `npm run build` prove the repository is
internally consistent and prove nothing about campus. `check-vpn-chain.sh` is the only
check that compares a documented value against the world unattended. Everything else about
campus needs a human on the network, so the route from that human to the frontmatter is
the whole design.

## One applier, four front ends

```
                        tools/check-record.mjs
                   parse() resolvePage() applyCheck()
                                |
        +-----------+-----------+-----------+-----------+
        |           |           |           |
  workflow      npm run     --issue=N    verify.sh --report
  issue -> PR   record      local from   prefilled URL
                local ->    an issue     (no write access)
                commit
```

Four routes, one applier, because the rule about what may write a date has to be the same
rule in all of them. A contributor touches the loop twice: one dropdown and a submit, then
a maintainer's merge. A maintainer with the hardware in front of them touches it twice on
their own terminal and never opens the issue board.

## Only "worked exactly as written" writes a date

`Worked, but a step needed adjusting` and `Did not work` print what needs fixing and change
nothing. A date on a page whose steps had to be worked around is exactly the false
verification `AGENTS.md` rule 5 exists to prevent, and the adjustment is the report the
page most needs anyway.

Dates are pattern-matched, refused if in the future, refused if more than two years old. A
future date is a typo, and stamping it would poison the staleness horizon.

`resolvePage()` never guesses. Unresolvable input is a hard error listing candidates. A
page declaring no `os` array is rejected with its own message: under the two-state contract
it has nothing to check, and a date on it would render nowhere.

## Frontmatter is rewritten line by line, never round-tripped

The `yaml` library reserialises, which reorders keys and drops the comments several pages
carry. The rewrite sets `lastChecked` and asserts that it touched no other key before
writing.

One key, because there is no `status` field to keep in agreement with it. That is the
point of the two-state contract: the state and its date cannot contradict each other.

## A record covers both languages, unless the mirror is stale

A check confirms a procedure, not a piece of prose. Both languages take their commands from
the same `facts/` entries and the work is carried by the same script, so a record filed
against either language stamps both, and the German page's `translatedFrom` is recomputed
from the English file's new blob sha afterwards.

That reasoning holds exactly as far as `check-translations.sh` holds. The recorded sha
matching the English source is the mechanical guarantee that the German page describes the
same procedure. So when the mirror's `translatedFrom` is already stale, only the named page
is stamped, and the reason is reported. A stale translation may have moved on from what was
checked, and carrying a stamp across that gap would be the one false claim this design must
not make.

It never carries across operating systems. Both languages describe the same three blocks,
and running one of them is evidence about that one.

## Scheduled checks keep one issue each, not one per run

`check-fact-urls.sh` and `check-staleness.sh` join `check-vpn-chain.sh` on a weekly cron,
each piped through `upsert-issue.mjs`, which finds an open issue by exact title and updates
it rather than filing another. A value wrong for six weeks is one issue with a history
instead of six issues.

`npm run check:drift` runs the same three locally. The workflow is a scheduled invocation
of a command a maintainer can run by hand, not logic that exists only inside a workflow
file.

Staleness is deliberately not part of `npm run check`: an unrelated pull request must not
fail because a different page aged.

## A button on the page, not an instruction to find a form

`ReportButton.vue` became `PageActions.vue`, carrying three links instead of one: the
existing "Something wrong here?", a new "This worked for me", and the edit link the default
theme used to render on its own. All three hand something back to the repository, so they
belong in one row, and the pager below stays navigation.

This is the direct answer to "say so". "This worked for me" is hidden on pages that declare
no `os`, since there is nothing there to report a run of.

`--report` prints the ordinary human summary and then the prefilled URL. It never sends
anything: the repository is public and the payload carries machine state, so the
contributor sees what would be published before it is published. The outcome dropdown is
prefilled only when every check passed, because a failing script may mean the page is wrong
or may only mean the reader is off campus, and the script cannot tell those apart.

`REPORT_PAGE` is set explicitly in each script rather than derived from the directory name,
because `scripts/network/` documents `/en/network/ethernet-802-1x`.

A failing verify script does not block `npm run record`, it is printed. Several of these
scripts check something narrower than the page covers, so a hard gate would be wrong more
often than right. Making the failure visible at the moment of stamping is the safeguard.

## Staleness is a clause on the date, not a third state

Past `stale_after_days`, the existing label carries its age. Same dot, same two states:

```
checked 2026-07-02
checked 2025-11-14, 9 months ago
not checked yet
nothing to check here
```

The age is rendered in months from the date, so it follows `stale_after_days` rather than
restating it.

The fourth line is a state of the *question*, not of the page: it says the check does not
apply here, never that the page is correct. The component keeps its slot rather than
hiding, so the marker is present on every page and its absence never reads as an oversight.
Worth stating because the voice table bans status seals, and that distinction is what keeps
this on the right side of the rule.

Two dates on a page, deliberately different in form. The status marker prints
`checked 2026-07-02` in full, because it is a claim about a person running steps and has to
be readable as a date. The footer prints `Last edited 3 weeks ago`, because the question a
git timestamp answers is how old the file is, and converting a date into that answer is
arithmetic the reader should not have to do. The exact date stays in `datetime` and in the
tooltip.

## Rule 5 was amended to admit the audited route

As worded before this, `AGENTS.md` rule 5 forbade the pipeline: it required a date be added
only for your own run and never for a run you only heard about. A maintainer merging a
check-record pull request is adding a date for a run they only heard about.

The rule was right about hearsay and wrong about the one audited route that is not hearsay,
so it now permits a date "from a check record filed by the person who ran them" and nothing
else. The route stayed narrow instead: the workflow adds a date and nothing else, and only
on one outcome.

## The issue body is untrusted input from the public internet

- It reaches the workflow through an environment variable, never interpolated into a `run:`
  line.
- No contributor prose reaches the repository. The pull request carries a machine-generated
  ISO date and a link to the issue for everything else.
- The page path is resolved against files that exist, so it cannot address anything outside
  `content/`.
- The date is pattern-matched and range-checked.
- `redact()` strips identifiers from the `--json` payload before it is ever put in a URL.

Generated issues and comments state observed value, documented value and date. No fault, no
intent, no attribution to anyone.

## Left out

- Rewriting `check-translations.sh` to hash the body rather than the whole file. It would
  make the `translatedFrom` bump unnecessary, but it changes an existing check's meaning and
  was not needed for this to work.
- Any automatic edit to page prose. Every decision here stops at frontmatter.
