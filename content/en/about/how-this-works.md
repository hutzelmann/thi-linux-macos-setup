---
title: How these pages are kept
description: What this project is, what it never does to the campus network, and how to contribute.
---

# How these pages are kept

## What this project is

Community-written setup notes for Linux and macOS at THI. Anyone can read them, anyone
can correct them, and they are in the public domain.

## What this project is not

Not official. Not affiliated with, endorsed by, or speaking for university IT. Not a
support channel, and not a place that can fix your account.

There are no commitments here: no accuracy guarantee, no promise that any topic gets
covered, no response time. The one thing this project does offer is a feedback loop: if
something is wrong, say so, and it gets corrected in the open.

For anything involving your account, your quota or your hardware, the official channels
are the ones that can actually change something:

- **[${facts.official.department}](${facts.official.service_url})**: the university's own
  information pages.
- **[Knowledge base](${facts.official.kb_url})**: THI's public articles. Mostly
  Windows-oriented, which is why this project exists, but authoritative where it
  overlaps.
- **${facts.official.support_mail}**: where a person answers. The IT pages state that
  support is currently by mail.

Note that [${facts.official.ticket_url}](${facts.official.ticket_url}) on its own is the
ticket system and needs a login; the knowledge base lives under `/help` on the same host.

## Why pages carry dates instead of checkmarks

Campus infrastructure changes quietly. A print server is renamed, a certificate authority
changes, a hostname moves, and notes written six months ago stop matching reality without
anyone noticing.

So pages state **when a human last checked them**, and some say plainly that nobody has.
A date you can judge for yourself is worth more than a green tick that means nothing.

## What this project never does to the campus network

Worth stating plainly, because a project that documents infrastructure without asking
permission should be precise about its own limits:

- **No credentials, anywhere.** Not in this repository, not in automation, not in any
  script here. The campus password is a universal credential that reaches mail, grades
  and personal data, and no convenience justifies storing or automating it.
- **No scanning.** Checks contact only endpoints that are already documented, using
  ordinary client protocols, at the volume of a single ordinary user. No ranges, no
  enumeration, nothing that resembles probing.
- **No automated trust changes.** Certificate authorities and fingerprints are only ever
  changed by a person who confirmed them out of band. An observed value is never
  promoted to a documented one automatically.
- **No personal data.** Usernames, addresses and paths are replaced with placeholders,
  and the build fails if one slips through.

## How to correct or confirm a page

Corrections are the most valuable thing, and the bar is deliberately low.

- **Something wrong on a page?** Use the link at the bottom of it. The report arrives
  with the page already filled in.
- **Tried the steps and they worked?** Use *This worked for me*, at the bottom of every
  page that has steps. That is the contribution most in demand, and the one this project
  had no way of accepting until recently.
- **Want to edit directly?** Every page has an *Edit this page on GitHub* link. No local
  setup, no git knowledge; GitHub handles the rest.

Contributions are released into the public domain under CC0, and pseudonymous
contributions are fine. Documenting a workaround under your real name carries more risk
for a student than for a member of staff, and equal participation should not require
equal exposure.

## What happens after you file a report

Worth spelling out, because a report that vanishes into an issue tracker is a report
nobody files twice.

**You press *This worked for me*.** The form opens with the page, your operating system
and today's date already in it. One question is left, and it is the only one a machine
cannot answer: did the steps *as written* get you there, or did you have to work around
one of them.

If you ran a script from the page, `./scripts/<area>/verify.sh --report` fills the form in
more completely, including what the script observed. It prints a link and sends nothing,
so you see the whole thing before deciding to publish it. Usernames and home paths are
stripped before they reach the link.

**A workflow reads it.** If you reported that the steps worked as written, it opens a
pull request adding one line to the page: your date, under the operating system you
said you ran it on. Nothing you wrote is copied into the repository: the pull request carries a date and a link back to
your report, and that is all.

That is why the form asks which system you used. Every page here gives Arch, Debian and
macOS different steps, so following it on one of them is evidence about that one. Your
date lands on that block and leaves the other two exactly as unchecked as they were.

**A person merges it.** That is deliberate. The date is the project's only claim, so a
human agrees to it before it is published.

**If the steps did not work as written**, no date is added, and it would be dishonest to
add one. The report is labelled and stays open as a work item instead. That is the more
useful report of the two, and it is what the *Known quirks* section of a page is made of.

**Nothing here is a promise.** No response time, no guarantee anybody picks it up.

## What runs automatically, every week

Once a week, three checks run on their own. Each keeps a single issue up to date rather
than filing a new one every time, so a value that has been wrong for a month is one
thread with a history.

- The VPN page's central claim is re-tested against the gateway, which is publicly
  reachable. If THI starts serving a complete certificate chain, the check says so and
  the page gets simpler.
- Every URL written down in `facts/` is asked whether it still answers. Vendors move
  downloads, and no page edit would ever reveal it.
- Pages waiting for somebody to follow them are collected into one list.

None of these ever changes a documented value. An observed value is not a verified one,
so a difference becomes an issue for a person to read, never an edit.

Checks are also shown their age. Past ${facts.project.stale_after_days} days a page still
says when it was checked, and adds how long ago that was. Nothing is retracted and no
page is marked wrong; you are simply told how old the claim is, which is the thing you
need in order to judge it.

The full contribution guide lives in
[CONTRIBUTING.md](https://github.com/${facts.project.repo}/blob/main/.github/CONTRIBUTING.md).
