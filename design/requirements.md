# Knowledge Base: Requirements & Feature Ideas

Last updated: 2026-08-09
Companion files: `stack-decision.md` (architecture and library choices), `decisions/` (what
was decided, when, and why)

The living register of what this project is trying to be. Requirement states in §2 are
checked against the tree, not remembered, and `R<n>` refers to this file and nothing else.
`AGENTS.md` rules are cited in full, as `AGENTS.md rule 5`. See `README.md` in this
directory.

---

## 1. Purpose

A public knowledge base of campus setup notes, covering Arch, Debian and macOS, written by
and for an open community of students and staff, both served equally (R31, §5.5).

Two problems drive the design:

1. **Campus infrastructure changes over time.** Print servers, queue names, VPN gateways,
   eduroam certificates, SSO endpoints, proxies and license servers all shift in minor
   details. Notes written months ago quietly stop matching reality.
   **OS/package drift is explicitly out of scope**, not a concern.
2. **Some setups are tedious.** Printing, VPN configuration, network shares, email and
   eduroam each mean drivers, certificates and fiddly settings that take an afternoon to
   get right. Prebuilt, known-working containers remove that overhead where the domain
   allows it. *Printing is one example among several; the design generalises (§4.3).*

> **Positioning (§5).** This is an unofficial, community-maintained set of notes. It makes
> no commitments, claims no endorsement, and is not a support channel. Wording throughout
> the project (docs, issues, commits) must reflect that. See §5 before writing anything
> public.

**The hard constraint:** the drift lives *behind a network boundary*. Much of it is only
observable from inside the campus network, so verification cannot run on GitHub-hosted
runners. This shapes the entire verification architecture (§4.1).

**Unifying principle:** the container is *both* the test environment and the shipped
artifact. One Dockerfile, two purposes. Never maintain separate "test" and "user" images.

---

## 2. Requirements

Every requirement carries a state, so that one which was superseded or never built says so
rather than reading as a promise. States are as of the date at the top of this file, and
were checked against the tree rather than remembered:

| State | Meaning |
|---|---|
| built | A mechanism in the repository does it |
| enforced | A rule in `AGENTS.md` that `npm run check` fails on |
| held | A policy the project follows, with nothing to build |
| partly | Done in part; the note says which part is missing |
| superseded | Overtaken by a later decision, which the note names |
| not built | Not implemented, and still wanted unless the note says otherwise |

### Site

| # | Requirement | Hard/Soft | State |
|---|---|---|---|
| R1 | Public hosting on GitHub Pages, static output only | Hard | built |
| R2 | Fast navigation: SPA-style client routing, no full page reloads | Hard | built |
| R3 | Cacheable in the browser (service worker precache; offline-capable) | Hard | not built |
| R4 | Tabbed code snippets per system: Arch, Debian, macOS (more later) | Hard | superseded |
| R5 | Fuzzy search, client-side, no external service (no Algolia account) | Hard | built |
| R6 | Content authored in Markdown | Hard | built |
| R7 | Scripts and containers live in the repo as real, testable files and are embedded into docs, with no copy-paste duplication | Hard | partly |
| R8 | Open source, permissive license, actively maintained | Hard | built |
| R9 | "Full framework": batteries included, not a pile of glue | Soft | built |
| R10 | OS selection is documentation-wide and persists across visits | Hard | built |
| R11 | First visit auto-detects OS from user agent (or similar) | Hard | built |
| R12 | **Arch Linux is the default** for all non-macOS visitors | Hard | built |

**R4 superseded.** OS variants are containers whose visibility is CSS keyed off
`html[data-os]`, not tabs, and `AGENTS.md` rule 7 now forbids a second tab axis outright.
See `decisions/0001-project-setup.md`.

**R7 partly.** The scripts are real files and are not duplicated, but they are no longer
embedded into pages. `tools/build-scripts.mjs` bundles each into a standalone file and
`ScriptDownload.vue` offers it for download, so a reader runs the script rather than reading
it inline. Worth flagging because `stack-decision.md` names VitePress's native
`<<< @/scripts/...#region` embedding as one of the two requirements that chose the
framework, and that feature is now unused.

**R3 not built.** No service worker exists. Nothing depends on it.

### Verification & delivery

| # | Requirement | Hard/Soft | State |
|---|---|---|---|
| R13 | Every manual is backed by a script that can be executed to check it; documentation is executable, not prose | Hard | partly |
| R14 | **Campus infrastructure** drift is detected without any local change | Hard | partly |
| R15 | Prebuilt containers published as ready-to-run artifacts for tedious setups, where the domain permits it | Hard | not built |
| R16 | A failing verification must produce a tracked, actionable signal, not just a red mark | Soft | built |
| R17 | Readers can see how recently a page was last checked, per OS, stated as an observation and never as a guarantee (R29) | Soft | built |
| R18 | Verification requiring campus-network presence must run from inside that network | Hard | not built |
| R19 | OS/package drift is **out of scope**; do not build for it | n/a | n/a |
| R20 | **No university credentials anywhere**: not in CI secrets, the repo, or the prober. The SSO password is a universal credential (it can alter student grades); it is never stored or automated | Hard | held |
| R21 | Manual verification is permanent and first-class; it must be tracked, dated, and its staleness surfaced | Hard | built |
| R22 | Checks follow one uniform schema across all domains (printing, VPN, shares, email, WiFi, …) so adding a domain is cheap | Hard | built |
| R23 | Documented configuration values live in data, referenced by both the docs and the checks, never typed twice | Hard | enforced |
| R24 | **Agent-operable**: checks are machine-readable, emit structured output, and declare their own prerequisites | Hard | partly |
| R25 | Agents operate **only inside disposable containers**, never against host state; repo mounted read-only | Hard | not built |
| R26 | Agent changes land as pull requests, never directly on main | Hard | not built |
| R27 | Trust material (certs, CAs, fingerprints) is **never** updated automatically from observed values; out-of-band human confirmation required | Hard | enforced |
| R28 | Unofficial and community-maintained. No affiliation or endorsement implied; official support channels are linked first, on every page | Hard | held |
| R29 | **No commitments of any kind**: no accuracy guarantee, no coverage promise, no response time. The only contract is the community feedback loop | Hard | enforced |
| R30 | Checks touch only documented endpoints, using ordinary client protocols, at low volume. No ranges, no enumeration, nothing resembling a network scan | Hard | held |
| R31 | Students and staff are served **equally**, with no assumed technical background and neither group second-class | Hard | held |
| R32 | Contributing and reporting must not require git proficiency, the command line, or opening a pull request. A GitHub account is the accepted floor | Hard | held |
| R33 | Pseudonymous contribution is permitted | Hard | held |
| R34 | Reports and check output **redact identifiers by default** (usernames, home paths, hostnames, addresses) | Hard | built |

**R13 partly.** Six scripts cover Wi-Fi, VPN, printing and shares. The policy and device
pages have none, and `npm run record` skips the script step for them by design.

**R14 partly.** `drift.yml` runs three checks weekly with no local change: the VPN chain,
the fact URLs and page staleness. Everything else about campus still needs a person on the
network, which is R18.

**R18 not built.** It needs a host that sits on the campus network permanently. Who owns
that machine is still open, in §6.

**R15, R25, R26 not built.** No container is published as an artifact: `test/printing/`
builds throwaway images to exercise the install script and nothing more. There is no agent
harness, so the two rules governing one have nothing to govern yet. Both stay as written for
when there is.

**R24 partly.** Every script emits `--json` on one schema. Prerequisites are documented in
prose and are not machine-readable, so a caller cannot ask a script what it needs.

### Languages

| # | Requirement | Hard/Soft | State |
|---|---|---|---|
| R35 | Two locales, **German and English**, both first-class. **English is the single source of truth**; German is a translation | Hard | built |
| R36 | German strings quoted from university systems (form labels, portal menu paths, policy titles) appear **verbatim in both locales**, with a translation in parentheses on English pages | Hard | held |
| R37 | Configuration facts (R23) are **locale-neutral and stored once**: hostnames, ports, queue names, paths, fingerprints, commands. A translated hostname is a bug | Hard | enforced |
| R38 | Every translated page records the source revision it was translated from; CI detects translations whose source has since changed | Hard | enforced |
| R39 | A stale translation is **marked in the UI**, never served silently as if current | Hard | superseded |
| R40 | Machine translation is permitted and expected. The PR must declare it, and review must confirm that no value, command or quoted UI string was altered | Hard | not built |
| R41 | Every page declares `status` and `lastChecked` in frontmatter; the status board is generated from them, never hand-written | Hard | superseded |

**R39 superseded.** `check-translations.sh` fails the build on a stale translation, so one
cannot reach a reader and there is nothing to mark. The banner this asked for would only
ever render on a site that could not have been published.

**R40 not built.** Nothing in the pull request template or `CONTRIBUTING.md` asks a
contributor to declare machine translation, and no review step checks it.

**R41 superseded.** There is no `status` field. A page is checked, for one operating system,
exactly when it carries a `lastChecked` date for it, so the state and its date cannot
contradict each other. See `decisions/0001-project-setup.md` and the page contract in
`AGENTS.md`.

---

## 3. Constraints & clarifications

**R3: SPA ≠ cached.** Client-side routing is R2. Browser caching means a service worker
precaching the app shell and docs. Separate features, separate solutions.

**R11 collapses to one check: "is this a Mac?"** UA cannot reveal a Linux
distro (`X11; Linux x86_64`; `userAgentData.platform` returns just `"Linux"`). Since Arch
is the default (R12), Linux, Windows and unknown all fall through to the intended value.
Only macOS/iOS needs correction. Consequences:

- **Flash-of-wrong-OS.** Prerendered HTML ships Arch active; Mac visitors would see Arch
  on first paint. Needs a blocking `<head>` script (dark-mode pattern).
- **Explicit choice wins forever.** Once the user picks, never re-run detection.
- **Debian users get a silent wrong default.** A UI problem, not a detection one, so the
  switcher must be always visible in the navbar.

**R14: on-push CI cannot satisfy this.** Drift happens when *you* change nothing. Only
scheduled runs catch it.

**macOS cannot be containerized.** Arch and Debian verify in containers; macOS must run on
a GitHub Actions `macos-latest` runner. This asymmetry is structural; plan for it rather
than working around it.

---

## 4. Feature ideas

Not decided. Ordered roughly by value-to-effort.

### 4.1 Catching campus drift

**Reframe: fingerprint the environment, don't run installs.** University IT drift shows up
as *facts about the environment*, not as failing package managers. Assert the facts
directly. It takes seconds instead of minutes, gives a precise diff instead of "a script
failed somewhere", and needs no privileged container.

Candidate fingerprint entries:

- Print server hostname → resolves? same address? IPP listening on 631?
- Documented queue names still present in `lpstat -a`
- eduroam / VPN CA certificate fingerprint, plus **days-until-expiry** (catches breakage
  *before* it happens, not after)
- SSO endpoint reachable, login form action unchanged
- Proxy PAC file content hash
- License server responding
- VPN gateway profile hash

Store the fingerprint as a committed file. Recompute on a schedule; when it differs, the
diff *is* the alert: it names the changed hostname or cert directly. Satisfies R14/R16.

**Where it runs: an on-campus prober, not a self-hosted runner.**

- A small job on a campus machine (lab box, VM, Raspberry Pi) runs the checks on cron and
  pushes results out to the repo.
- **Prefer this over a self-hosted GitHub Actions runner.** GitHub explicitly warns against
  self-hosted runners on *public* repos: fork pull requests can execute arbitrary code on
  the runner, which here would be a machine inside the university network. A prober needs
  only outbound HTTPS and has almost no attack surface.
- If a self-hosted runner is used anyway, it must live in a **private** repo, or be
  restricted to `schedule` / `workflow_dispatch` with fork PRs disabled.

**Split the lanes by what they need:**

| Lane | Needs campus? | Where |
|---|---|---|
| Lint, container **builds**, script syntax | No | GitHub-hosted CI |
| Campus fingerprint, functional print tests | **Yes** | On-campus prober |
| macOS | Yes + Apple hardware | Human-in-the-loop (§4.2) |

Containers can still be *built* in normal CI; only their *functional* verification needs
campus presence.

**Open question that could simplify all of this:** ~~is campus VPN access sufficient?~~
**Resolved: no.** The VPN requires interactive SSO, and that credential is universal and
high-privilege (R20). It cannot be automated or stored. The on-campus prober is
**permanent**, and physical presence is required.

**Consequence: the prober is credential-free.** It may only perform unauthenticated
observation:

| Probe-able without credentials | Requires auth → manual lane |
|---|---|
| DNS resolution, address stability | Anything behind SSO |
| TCP reachability (631, 443, …) | Authenticated portals |
| TLS cert fingerprint + **days-to-expiry** | Licence checkouts |
| IPP `Get-Printer-Attributes` | Personal queue state |
| `lpstat -a` against the print server | |
| Public endpoint content hashes | |

Use this split to decide what belongs in the fingerprint at all. If a check needs SSO, it
is a manual checklist item by definition; do not attempt to automate it.

**Conduct: this is politically sensitive, not only technical (R30).**

⚠️ **Avoid the word "scan".** What happens here is *checking a small set of documented
endpoints using ordinary client protocols, a few times a day*. That description is
accurate, and it is also the one that does not sound like something out of an acceptable
use policy. Use it in the repo, in commit messages, and in conversation.

Keep the behaviour matching the description:

- Named endpoints only, the ones the notes already tell users to connect to.
- Never address ranges, never ports the notes do not mention, no enumeration, no
  vulnerability probing.
- Low frequency. Nothing that would stand out in a log.
- Identify the prober where the protocol allows (User-Agent, hostname).
- Keep a short written rationale in the repo, so the project can explain itself calmly if
  ever asked.

**Skip ≠ fail.** The prober must record "campus unreachable, check skipped" distinctly
from "check ran and failed". If the host is a laptop that leaves campus, conflating these
produces false alarms, and false alarms are how monitoring gets ignored.

**Record the vantage point.** Campus may look different from wired, eduroam, or a lab
VLAN. Each fingerprint run should note where it was taken from.

### 4.2 Manual verification as first-class infrastructure

Manual checks are permanent (R21), not a gap to be closed. They rot because nobody
remembers them, so **automate the nagging, not the test**.

- **Verification records.** A `verifications/` directory of dated YAML files, one per run,
  committed by PR: what was checked, by whom, from where, result. The site aggregates
  these into the per-page "last verified" badges (R17).
- **Max age per check.** A scheduled workflow reads the records and opens an issue when
  anything goes stale: *"macOS print test last verified 47 days ago"*. This needs no
  campus access, so it runs in ordinary GitHub-hosted CI.
- **`verify.sh` prints a pasteable result block**, shaped so it drops straight into a
  verification record or an issue. Same script serves the maintainer's ritual and a
  reader checking their own setup.
- **Readers report drift.** Every page gets a "did this work?" link to a prefilled issue
  template naming the page. Free on a static site, and the readership is already on
  campus: distributed drift detection at no cost.

**macOS** has no automation path: no containers, no campus runner, and no VPN (R20).
Periodic human ritual is the design, not a shortfall.
*If* an Apple-Silicon Mac lives on campus long-term, Tart can host macOS VMs under Apple's
virtualization framework and could run a prober. Only worth it if the hardware exists.

### 4.3 The check taxonomy (generalises across all services)

Printing was one example. VPN config, network shares, email, WiFi/eduroam and future
domains all decompose the same way. Define the layers once so adding domain N+1 is cheap.

| Layer | What | Credentials? | Lane |
|---|---|---|---|
| 1 | Reachability: DNS, address stability, TCP/TLS connect | No | prober |
| 2 | Trust material: cert fingerprint, CA chain, **days-to-expiry** | No | prober |
| 3 | Capability negotiation: what the server announces pre-login | No | prober |
| 4 | Authenticated function: log in, mount, send, submit | Yes | manual (or test account) |
| 5 | End-to-end / physical outcome | n/a | human |

**Layer 3 is the seam to exploit:** it is unauthenticated *and* it is exactly what the
manuals document.

| Domain | Layer 1–3, credential-free | Layer 4–5 |
|---|---|---|
| **WiFi / eduroam** | RADIUS server cert fingerprint + CA + expiry; published CAT profile hash | Association in the wild |
| **VPN** | Gateway reachability, TLS cert, published client-profile hash, mandated client version | Interactive SSO connect (R20: manual, permanent) |
| **Email** | IMAP `CAPABILITY` banner, SMTP `EHLO` (STARTTLS? offered AUTH mechanisms?), autoconfig/autodiscover XML endpoint | Login, send/receive |
| **Network shares** | SMB dialect + signing requirements from protocol negotiation, DFS referral names, host stability | Mount, read, write |
| **Printing** | `lpstat -a`, IPP `Get-Printer-Attributes`, `printer-state-reasons` | Job completes; paper emerges (§4.3.1) |

**Highest-value single check: the eduroam RADIUS certificate.** It drifts, it breaks every
user simultaneously, and a changed cert that users blindly accept is a credential-theft
vector. Expiry monitoring turns a bad morning into a calm page edit.

**Ask IT for a dedicated low-privilege test account**, a throwaway mailbox and one share,
valuable for nothing. This legitimately automates layer 4 without touching the universal
credential (R20). A normal request; worth making even if declined.

#### 4.3.1 Printing: how much needs a human

Layers 1–4 catch nearly all campus drift: queue renamed, server relocated, job rejected
after a driver change. Layer 5 catches only rendering faults (page size, PPD change
garbling output), which drift rarely. **Monthly cadence suffices**, and it saves paper.

- **Print a generated code and date on the test page.** Confirmation becomes "I received
  code 7F2A", not a remembered "it worked": auditable, not confirmable from memory.
- **Split rendering from the device.** Print the same job to a PDF queue and compare;
  catches driver/PPD drift automatically, narrowing the human check to hardware failure.

### 4.4 Documented values are data, not prose

Every manual states facts: hostnames, ports, cert fingerprints, share paths, profile
hashes. Keep them in a YAML file, not typed into Markdown.

- The docs render them through a component; the prober asserts them; both reference the
  same **check ID**.
- Drift then means *one file changes* and manual + checks update together, the
  "don't copy-paste the script" principle applied to configuration facts.
- A failing check names the page that is now wrong, instead of leaving you to grep.

⚠️ **Before publishing:** a public repo mapping internal hostnames, share paths and
infrastructure topology deserves a sanity check with IT. Most of it is already in the
manuals they distribute, but not necessarily all of it.

### 4.5 Freshness signals in the docs

⚠️ **Wording matters here more than anywhere else.** These render on every page, and the
wrong phrasing turns an observation into an implied guarantee (R29).

- **State observations, not assurances.** *"Last checked 2026-08-01 by a contributor"*,
  not *"Verified ✅"*. Same information, no promise attached.
- **No green checkmarks or seals.** They read as certification and imply someone stands
  behind the result. Neutral typography, dates, and plain language.
- **Show age, not status.** *"Checked 41 days ago"* lets the reader judge. *"Current"* or
  *"Up to date"* is a claim the project cannot make.
- **Link the run that produced it**, so the claim is auditable rather than decorative.
- **Readers report drift.** Every page carries a "did this work for you?" link to a
  prefilled issue naming the page. Free on a static site, the readership is already on
  campus, and per R29 this feedback loop *is* the project's only commitment.

### 4.6 Agent readiness

**The sandbox already exists.** The containers built for §4.7 *are* the reversible
temporary layer: overlayfs, `--rm`, discard. An agent debugging a Debian manual runs
inside the container with host networking, so it still reaches campus while the host
stays untouched. Make this the mandated entry point, not an option.

**What makes the repo agent-operable (R24):**

- **Structured output.** `verify.sh --json` → check ID, expected, actual, timestamp,
  vantage point. An agent cannot debug prose. Highest value per unit of effort.
- **Checks declare prerequisites.** Campus? credentials? physical presence? which OS?
  Without this an agent will claim to have run what it structurally cannot, which is worse
  than not running it at all.
- **Capture evidence, not just pass/fail.** Resolved IPs, full cert chain, raw `EHLO`
  response, IPP attribute dump. This decouples debugging from network access: an agent
  off-campus diagnoses from yesterday's record rather than needing to be on campus.
- **One-command reproduction.** `./debug.sh <check-id>` spins the right container, runs the
  check, leaves the agent inside. Repo mounted **read-only** plus a scratch dir, so the
  agent proposes diffs instead of mutating source while experimenting.
- **`AGENTS.md` at repo root** stating the contract: container only, never host config,
  never main, all changes as PRs, never handle credentials (R20).

**Two hard safety rules:**

1. ⚠️ **Never auto-update documented cert fingerprints from observed values (R27).** If a
   probe is MITM'd, an obliging agent updates the documented eduroam fingerprint to the
   attacker's, and the manual then instructs every student to trust it. This inverts the
   entire purpose of documenting fingerprints. A changed fingerprint is an *alert for a
   human*, confirmed out-of-band against an official IT source. Never a patch to apply.
2. ⚠️ **Probe output is untrusted input.** Service banners, autodiscover XML and HTTP
   responses are attacker-influenceable in principle. They are data for an agent to
   analyse, never instructions to follow.

**Review gates.** A drift-fix PR needs a human who can tell "IT changed something" from
"the probe is flaky". `CODEOWNERS` on the facts file and on anything under trust material;
no auto-merge on either.

### 4.7 Container delivery

- **Publish to GHCR** (`ghcr.io`). Free for public repos, same auth as the repo, no Docker
  Hub pull-rate limits. Obvious fit given Pages hosting.
- **Multi-arch: amd64 + arm64.** Apple Silicon users are precisely the people most
  motivated to avoid a local driver install. Skipping arm64 loses the core audience.
- **Tag strategy:** `latest` + dated (`2026-08-02`) + sha. Manuals reference **dated**
  tags, so a doc page from six months ago still describes something that exists.
- **Ship a tested `run.sh` wrapper** instead of a six-flag `docker run` line in prose. It
  becomes another embedded, CI-verified script rather than a thing that silently rots.
- **`devcontainer.json`** for one-click VS Code environments: near-free given the images
  already exist, and doubles as the agent's sandbox (§4.6).
- **Renovate or Dependabot** on pinned versions: *low priority*, since OS/package drift
  is out of scope (R19). Only worth it to keep base images from going stale.

### 4.8 Printing containers: scope this carefully

⚠️ **The container story is weaker than it looks for printing, and it is worth deciding
early rather than discovering later.**

- **Network/IPP printers containerise fine.** CUPS in a container talking IPP over the
  network is straightforward and genuinely removes the driver pain.
- **USB printers need device passthrough** (`--device`, often privileged). Workable on
  Linux, fiddly to document.
- **Docker Desktop on macOS cannot pass USB through at all.** So the macOS users who most
  want to skip installing drivers are exactly the ones a USB-printing container cannot
  help.

Suggested scope: containers target **network printing**; USB on macOS stays a native
manual. State this limitation on the page rather than letting readers discover it.

---

## 5. Positioning & language

The project is not universally welcome. Wording is therefore a design constraint, not a
stylistic one. This section governs everything public: docs, README, issue templates,
commit messages, auto-generated alerts.

### 5.1 What the project claims

**Nothing.** Per R29, the only commitment is the community feedback loop: *these are
community notes; tell us when something is wrong and we will update them.* No accuracy
guarantee, no coverage promise, no response time, no support obligation.

Every page carries, in the footer:

- Unofficial and community-maintained
- Not affiliated with, endorsed by, or speaking for university IT
- **Official support channels, linked first**

### 5.2 Vocabulary

| Avoid | Use |
|---|---|
| scan, probe the network, monitor | check documented endpoints |
| verified, certified, guaranteed | last checked on *date* |
| supported, official, approved | community-maintained |
| tested and working | reported working by contributors on *date* |
| broken, outage, IT changed X without notice | observed value differs from documented value |
| ✅ / ❌ status seals | plain dates and ages |

### 5.3 Tone in automated output

Auto-generated issues and alerts are public and permanent. They must be neutral and
blameless: state what was observed, what was documented, and when. Never attribute
intent, fault, or negligence to anyone. An alert that reads as a complaint is a liability
the moment someone links it.

### 5.4 Presentation

- Do not use university names, logos or visual identity in ways implying endorsement.
- The repo and site name should not look official.
- Include a standard no-warranty disclaimer alongside the licence.
- Frame content as *"what worked for us"*, never as instruction issued with authority.

### 5.5 Audience & community

An open community serving students and staff equally (R31). The audience is not a
homogeneous technical readership. A professor and a first-semester student both need
eduroam, and neither should have to read shell to get it.

**Layer pages; do not fork them.**

- Documented values and the click-path come first, in plain language.
- The script and container follow as a *fast path* for those who want it.
- **Never** split into beginner/advanced pages; that doubles the drift surface, which is
  the one thing this project exists to prevent.

⚠️ **Design guardrail: keep exactly one tab axis.** The axis is OS (R4). Do not add
GUI-vs-terminal as a second dimension. Two axes means six variants per snippet and a
maintenance load that will end the project. Terminal instructions go *below* the prose,
not beside it.

**Equal does not mean identical.** Mailbox type, share paths, licence entitlements and
print quotas often genuinely differ by role. Carry that in the facts data (R23) and in
separate pages where the difference is real, never as another tab dimension.

**Participation:**

- **Pseudonymous contribution is permitted (R33).** Given §5.1, a student documenting a
  workaround under their real name carries risk a professor does not. Equal participation
  means not requiring people to be equally exposed.
- **A path that is not git (R32).** GitHub issue *forms* render as real forms and are a
  reasonable floor, but still require an account. Consider a second channel that feeds
  into issues for contributors outside technical departments.
- **Adopt a standard Code of Conduct** (e.g. Contributor Covenant). Students and staff are
  not institutional peers; contributions are judged on content, and the CoC is what makes
  that norm explicit rather than assumed.
- **Contributors must not make commitments on the project's behalf** (R29). Worth stating
  in the contributing guide, because someone eventually will in an issue thread.

**Privacy (R34).** Reports about email, shares and VPN naturally carry usernames, home
paths, hostnames and log excerpts. `verify.sh --json` should strip identifiers
automatically rather than relying on people to remember, and the issue template should say
so. Students are the more exposed group.

### 5.6 Two languages (R35–R40)

German and English, both real. This follows directly from R31: the audience includes
international students who do not read German and staff who work in it daily, and neither
group should be the one that gets the second-rate page.

**One direction of authorship.** English is the source; German is generated from it and
reviewed. Two originals means two things to keep true and no way to tell which is right,
the same trap as forking pages for beginners (§5.5), in another dimension.

⚠️ **Translation is a second drift axis.** AI makes the first translation cheap; it does
nothing for the second month. A German page whose English source changed is *wrong*, and
invisibly so. Treat it exactly like an unverified check: record what it was translated
from (R38), detect the mismatch in CI, and **say so on the page** (R39). Serving a
confident, stale German page is worse than serving English.

**What never gets translated:** documented values (R37: they live in the facts file and
render into both locales from one place), quoted German UI strings (R36: a translated
form label is an instruction the reader cannot follow), and scripts, code comments and
commit messages, which stay English throughout.

**Vocabulary (§5.2) applies to both locales.** The careful positioning language is not a
translation detail to be improvised: `verified` → `zuletzt geprüft am`, `supported` →
`von der Community gepflegt`. Fix these in a glossary before the first translation run, or
every batch will invent its own.

---

## 6. Open items

Resolved items name what resolved them, so a reader does not have to guess whether a
question was answered or abandoned.

### Still open

- [ ] What machine hosts the campus-side prober, and who owns it? A laptop means skip must
      not read as fail. Blocks R18.
- [ ] **Ask IT for a low-privilege test account**, which unlocks layer 4 automation.
- [ ] **Sanity-check with IT what infrastructure detail is publishable.**
- [ ] Who runs the macOS verification, and how often? macOS cannot be containerised, so this
      is a person or a `macos-latest` runner, and neither is arranged.
- [ ] Is a PDF-queue rendering comparison worth setting up, or is layer 5 enough?
- [ ] Glossary of positioning vocabulary (§5.2) in German. The voice table in `AGENTS.md` is
      English only, and the German pages were written without it.
- [ ] Does the German locale get its own issue templates, or is reporting English-only?
      (R32 says contributing must be low-barrier; an English-only form contradicts that.)
- [ ] Does the facts file need a role axis? Printing already carries a staff queue and a
      student queue as separate keys, which works but does not generalise.
- [ ] Search index size budget as the knowledge base grows.
- [ ] Should R15, R25 and R26 stay as Hard requirements? All three describe an agent and
      container delivery story that nothing has needed yet.

### Resolved

- [x] Persist OS site-wide or per-page? Site-wide (R10).
- [x] Default distro on generic Linux? Arch (R12).
- [x] Behaviour for Windows or unknown user agent? Arch (R12).
- [x] Keep auto-detect? Yes, scoped to a single Mac check (§3).
- [x] Is campus VPN access sufficient? **No.** Interactive SSO, and the password is a
      universal high-privilege credential, so the prober is permanent and on campus (R20).
- [x] Second contribution channel for non-git contributors? **Deliberately none.** Issues
      only, and a GitHub account is the floor (R32, knowingly relaxed in
      `decisions/0001-project-setup.md`). Revisit if a non-technical department is genuinely
      blocked by it.
- [x] Is i18n needed? **Yes, German and English**, English is source (R35 to R40, §5.6).
- [x] Schema for the check definitions and the facts file? `facts/<domain>.yaml`, one level
      deep by contract, one file per domain (`0001`).
- [x] JSON schema for check output? `json_result()` in `scripts/lib/facts.sh`, one shape for
      every domain (R22).
- [x] Max age per manual check before staleness is surfaced? `stale_after_days: 180` in
      `facts/project.yaml`, read by `check-staleness.sh` and by the page marker
      (`decisions/0002-validation-workflow.md`).
- [x] Cron cadence for the scheduled checks? Weekly, Monday 06:00 UTC, in `drift.yml`.
- [x] Domain rollout order? Moot. Wi-Fi, wired, VPN, printing and shares shipped together.
- [x] Which domains warrant containers at all? Printing only, in `test/printing/`. VPN and
      Wi-Fi were expected not to and do not.
- [x] Does `AGENTS.md` cover it, or is a per-directory contract needed? `AGENTS.md` covers
      it, and `npm run check` enforces the parts that can be enforced.
- [x] Naming convention for snippet regions in scripts? Moot. Scripts are bundled and
      downloaded rather than embedded, so there are no regions (R7).
