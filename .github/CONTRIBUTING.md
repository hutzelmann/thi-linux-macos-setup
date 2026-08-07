# Contributing

Anything you know that is not written down yet is worth more than perfect formatting of
what already is. Corrections especially.

You do not need to know git. You do not need to run anything locally. Pick whichever
level below fits what you want to do.

## Level 1 — tell us something is wrong

The link at the bottom of every page. It opens a short form with the page already filled
in. Half a sentence is enough: *"the PPD path is different on Ubuntu 26.04"*.

This is a real contribution, not a lesser one. A page nobody has corrected is a page
nobody has read carefully.

## Level 2 — say that it worked

If you followed a page on your own machine, please
[file a check record](../../issues/new?template=check-record.yml): which OS, what date,
and what happened — including "step 3 was wrong, here is what actually works".

Most pages here have never been verified by a second person. Changing that is the single
most useful thing available, and it needs no writing skill at all.

## Level 3 — edit a page in the browser

*Edit this page on GitHub* at the bottom of any page. GitHub makes you a copy, you type,
you describe the change, done. It becomes a pull request automatically.

For anything larger than one page, press `.` on the repository for a full browser editor.

## Level 4 — work on it properly

```bash
git clone https://github.com/hutzelmann/thi-linux-macos-setup
cd thi-linux-macos-setup
npm install
npm run dev          # http://localhost:5173
```

Node 22 or newer. Or open the repository in a devcontainer — locally in VS Code with
Docker, or in Codespaces — and everything is installed for you.

New page:

```bash
npm run new-page     # asks a few questions, writes the file and the sidebar entry
```

Before opening a pull request:

```bash
npm run check        # the same checks CI runs
```

## Things the checks will stop you doing

Not style preferences — each one exists because of a specific way documentation goes
wrong.

**Never put a hostname or queue name in a page.** They live in `facts/`, and pages
reference them as `${facts.printing.queue}`. When a server is renamed, one file changes
and every page follows. The print server here was renamed once already, and every note
that hardcoded it silently became wrong.

**Never commit personal data.** No usernames, mail addresses, `/home/<your-name>` paths or
log excerpts with identifiers. Use `<kennung>`, `<vorname.nachname>`, `<hostname>`. This
repository is public and history cannot be unpublished.

**Never claim a check you did not do.** `status: checked` with a date means a person ran
the steps on real hardware on that date.

**Never add a second tab dimension.** Operating system is the only one. Adding
terminal-vs-GUI as a second axis means six variants of every snippet and the project dies
of maintenance.

## How to write a page

Same order every time, because a reader in trouble scans rather than reads:

1. What this page gets you, in one sentence.
2. The official channel, linked first.
3. Documented values, from `facts/`.
4. The plain-language path — assume no terminal.
5. The terminal fast path, per OS.
6. How to verify it worked.
7. Known quirks.

Terminal instructions go *below* the plain-language ones, never instead of them. Both a
professor of literature and a computer science student need eduroam.

## Language

Pages are written in English and translated into German. Both matter: most people search
in German, and not everyone here reads it.

German words quoted from university systems — form labels, menu paths, policy titles —
stay in German in both versions, with a translation in brackets on English pages. A
translated form label is an instruction the reader cannot follow.

If you would rather write in German, do. Write the page, say so in the pull request, and
translation to English happens during review.

## Licence and names

Everything here is released into the public domain under
[CC0 1.0](../LICENSE). By contributing you agree to release your contribution the same
way. No attribution is required from anyone reusing it, including THI.

**Pseudonymous contributions are welcome.** Documenting a workaround under your real name
carries more risk for a student than for a member of staff, and equal participation
should not require equal exposure.

## What this project will not do

It will not become a help desk. Issues are for the pages, not for individual machines —
if your account is locked or your printer quota is empty, write to support@thi.de or see
the [THI IT service pages](https://www.thi.de/service/it-service/). They will be faster
than we are, and they can actually change things.

Nobody here can make commitments on the project's behalf, in an issue thread or anywhere
else. There are none to make.
