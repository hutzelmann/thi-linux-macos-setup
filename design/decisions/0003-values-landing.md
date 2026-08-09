# 0003: The locale landing page as a values sheet

Date: 2026-08-08 · Status: accepted · Landed: 2026-08-09

What `/en/` and `/de/` are for, once the site root has already asked the reader for a
language and an operating system.

## The problem: the page repeated what the reader had just been through

`content/en/index.md` carried nothing that was not already one click away.

| Element on `/en/` | Already existed |
|---|---|
| Name and tagline | `content/public/index.html`, the `h1` and the lede |
| "unofficial, not IT support" | the chooser lede and the chooser's `.unofficial` box |
| Link to the official IT service | the chooser's `.unofficial` box |
| Three feature cards | sidebar groups "Network" and "Printing and files" |
| Action "A new machine on campus" | sidebar, first item |
| Action "How this works" | sidebar group "About" |
| "Why this exists" prose | `content/en/about/how-this-works.md` |

The root already asks both questions it needs to ask and already states that the project is
unofficial, twice. `/en/` then stated it a third time and repeated the sidebar as cards. A
reader arrived having already chosen to be there and was sold the project again.

It also served neither of the two people who reach it. A first visit wants the order to do
things in, which is `content/en/start/new-machine.md`. A returning visit wants one value: an
SSID, a queue name, a print server. That was three clicks away, and embedded in prose on
arrival.

## The decision

`/en/` is the values sheet: every string a reader would retype into a settings dialog, in
one screen, each linking to the page that explains it. `layout: home` stays. The body is a
heading and a deck of five cards, and nothing else.

Row selection follows one test: **would a reader retype this into a settings dialog?** That
admits SSIDs, hostnames, queue names, EAP methods, CA names and domains. It excludes the
driver download URL, the PPD path and the job retention window, which are page prose or
script work. Cards hold at most five rows; a topic needing more rows needs its page.

Every value comes from `facts/` by substitution, including inside the Vue tags:
substitution runs on the markdown source before markdown-it, so a facts token inside a
component's slot is replaced like any other. No value is typed into the page.

## The headline names the system back

The reader picked an operating system at the root, so the headline says which one. All
three variants sit in the DOM and `os.css` shows the matching one, keyed off
`html[data-os]`, which the blocking head script sets before first paint. Same mechanism as
the OS blocks in the body, so there is no second way to do this and no flash of the wrong
system.

The navbar rule collapses Arch and Debian into "Linux" because it sits inside running text.
A headline answering a choice the reader just made keeps the three apart.

## The navbar title is hidden on both landing pages

The title in the corner is a link home, a landing page is home, and directly under it sits a
headline naming the same site.

The hook is `pageClass: is-landing` in frontmatter rather than the default theme's own
`.VPNavBar.home` class, which is assigned after hydration and absent from the
server-rendered HTML, so the title would be painted and then removed. `pageClass` lands on
the Layout element during rendering.

## A gap is shown where the reader meets it

The wired card's CA certificate row reads **not documented**, not a value.
`facts/network.yaml` records that absence deliberately: the official document enables
server-certificate checking and leaves the authority unselected, and the inspected working
profile carried neither value.

Putting that on the landing page makes the project's own rule visible at the point of use.
An admitted gap beats a plausible hostname, and saying so on the about pages is weaker than
showing it in the deck.

## Rejected

**A closing "Not official" section.** The footer says it on every page in both locales, with
links to the IT service, the knowledge base and the support address. One statement, in the
place that already carries it everywhere.

**A lede under the section heading.** Two revisions had one: first that the values could be
copied, then that the cards are not instructions and each links to a page. The copy line
described a mechanism that no longer exists, and the cards carry a "Full documentation" cue
on the heading row, which says the same thing where the reader is already looking. The
newcomer is served by the hero's brand button, not by a sentence there.

**A link at the foot of each card.** One more thing to read past on the way down. The cue
sits on the heading row instead, in the width a card actually has, and the heading carries
the brand colour so it reads as clickable before the cue is read at all.

**Click-to-copy values.** Built and then removed. The affordance needed padding reserved
inside the code element, and a value that wrapped left an empty padded box on the second
line, so the rows read as broken. The values stay selectable, which is what they were
before. If copy returns it needs to sit outside the code element rather than inside it.

**A check pill per card.** It turns the landing page into a status dashboard and competes
with the values for attention. `content/en/about/status.md` carries that table, every page
carries its own marker, and each card links to the page where that marker is.

## German points at English pages where it must, and says so

`content/de/index.md` mirrors the structure exactly: same hero shape, same lede, same five
cards, same rows.

Two of the five link to pages that do not exist in German yet. `ignoreDeadLinks` is false,
so linking a missing German page would fail the build. Those cards link to the English page
and say so in the link text, following the precedent set by the German sidebar's
"Alle Seiten (englisch)" entry. Translating those pages is separate work.

## Left out

- Any change to `content/public/index.html`. The chooser works and is understood.
- Any change to the sidebar.
