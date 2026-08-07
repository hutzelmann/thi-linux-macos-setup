---
title: How this works
description: What this project is, what it never does to the campus network, and how to contribute.
status: structured
---

# How this works

## What this is

Community-written setup notes for Linux and macOS at THI. Anyone can read them, anyone
can correct them, and they are in the public domain.

## What it is not

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
  Windows-oriented, which is why this project exists, but authoritative where it overlaps.
- **${facts.official.support_mail}**: where a person answers. The IT pages state that
  support is currently by mail.

Note that [${facts.official.ticket_url}](${facts.official.ticket_url}) on its own is the
ticket system and needs a login; the knowledge base lives under `/help` on the same host.

## Why pages carry dates instead of checkmarks

Campus infrastructure changes quietly. A print server is renamed, a certificate authority
changes, a hostname moves, and notes written six months ago stop matching reality
without anyone noticing.

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

## Contributing

Corrections are the most valuable thing, and the bar is deliberately low.

- **Something wrong on a page?** Use the link at the bottom of it. The report arrives
  with the page already filled in.
- **Tried the steps and they worked?** Say so. A dated check record from a real machine
  is what turns "written down" into "verified", and it is the contribution most in
  demand.
- **Want to edit directly?** Every page has an *Edit this page on GitHub* link. No local
  setup, no git knowledge; GitHub handles the rest.

Contributions are released into the public domain under CC0, and pseudonymous
contributions are fine. Documenting a workaround under your real name carries more risk
for a student than for a member of staff, and equal participation should not require
equal exposure.

The full contribution guide lives in
[CONTRIBUTING.md](https://github.com/hutzelmann/thi-linux-macos-setup/blob/main/.github/CONTRIBUTING.md).
