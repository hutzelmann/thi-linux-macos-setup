# design/

Why the repository is the way it is. Not documentation of how it currently behaves: that
is `AGENTS.md`, which `npm run check` enforces, and duplicating it here would produce a
second copy that nothing checks.

Published knowledge lives in `content/`. This directory is the repository's own reasoning,
which is why it is not called `docs/` (see `decisions/0001-project-setup.md`).

## Three kinds of file, and why each cannot rot

**`decisions/NNNN-*.md`, immutable.** A decision record says what was decided, on a date,
and why, including what was rejected. Once accepted it is never edited. If the decision
changes, a new record supersedes it and links back, and the old one stays as the record of
what was true then.

This is the `lastChecked` idea applied to reasoning. A dated statement about the past
cannot go out of sync with the present, because it never claimed to describe the present.
A document that describes current behaviour goes stale the first time somebody changes the
behaviour and not the document.

**`requirements.md`, living.** The register of what the project is trying to be. Every
requirement carries a state, so a requirement that was superseded or never built says so
instead of reading as a promise. Edited whenever a requirement's state changes.

**`stack-decision.md`, historical.** The framework evaluation behind `0001`. Kept at its
own path because `0001` cites it there, and carrying a dated note listing the assumptions in
it that have since changed. It is not edited to match them: a comparison matrix rewritten
after the fact stops being evidence of what was compared.

Anything that does not fit one of these three does not belong here. In particular, a plan
for work that has not happened yet is not a decision record. Either it lands and becomes
one, written in the past tense, or it is an issue.

## What went wrong before, so it is not repeated

Two design documents were written in `docs/design/`, in the future tense, each headed
`Status: approved design, not yet implemented`. Both shipped. Neither header changed. The
result was a second documentation directory whose files contradicted `0001`, described work
as pending that was live in the tree, and carried session scaffolding ("rebase notes",
"implementation waits until that session's work has landed") that meant nothing once the
work landed.

They are now `decisions/0002-validation-workflow.md` and `decisions/0003-values-landing.md`,
rewritten in the past tense with the implementation specs removed. The specs were describing
code, and the code describes itself.

## Adding a decision record

1. Next free number, `NNNN-short-slug.md`.
2. Header: `Date: YYYY-MM-DD · Status: accepted`, plus `· Landed: YYYY-MM-DD` once the work
   is in the repository. Both are dates, so neither can become untrue.
3. Past tense. What was decided, why, and what was rejected. Rejected alternatives are the
   part a later reader cannot reconstruct from the code.
4. No implementation checklist, no file-by-file spec, no verification list. Those are the
   diff, `AGENTS.md` and CI respectively.
5. `AGENTS.md` rules 1 to 9 are cited in full, as `AGENTS.md rule 5`. `R<n>` refers to
   `requirements.md` and nothing else. The two lists collided for a while and code cited
   both in the same notation, which made `R9` mean two different things.

No em dashes. The voice table in `AGENTS.md` applies to anything written here from
2026-08-09 on; `stack-decision.md` predates it and is left alone.
