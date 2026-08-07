# Knowledge Base: Stack Decision

Status: **decided. VitePress 1.x, bilingual DE/EN**
Last updated: 2026-08-07

---

## 0. Decision

**Option A: VitePress 1.x** (§4), with **German and English as parallel locales** (§7).

Why, in one line each:

- **R7 and R5 decide it.** Native `<<< @/scripts/…#region` embedding and MiniSearch
  edit-distance search are the two requirements the project's premise rests on, and they
  are the two VitePress does best.
- **Docusaurus's advantages were for features we do not use.** No blog, no doc
  versioning, no plugin exotica, and its `groupId` tab-sync edge was already nullified
  by the R11 analysis (§4).
- **Minimal by preference.** The content is markdown plus shell one-liners. A webpack
  build and a React toolchain would be carried for no return.

**Accepted risk: the 1.x line is frozen.** 1.6.4 shipped 2025-08-05; all work is on v2,
in alpha since early 2025 (alpha.19, 2026-08-02). Sized deliberately:

- v2 is a *modernization, not a rewrite*: Vite 8, Node ≥22, Shiki v3, `markdown-it-async`,
  `@mdit/*` plugins, a normalize-level CSS reset, and a set of config renames. No change
  to the content model or the theme architecture.
- The two areas v2 is actively developing are **snippet regions** (region-marker engine,
  include-by-header-anchor, tagless region ends) and **local search** correctness. Those
  are R7 and R5. The maintainers are investing in exactly what this project depends on.
- No v1→v2 migration guide exists in the repo yet. Build on 1.6.4; migrate when v2 is
  stable. **Do not ship a public site on an alpha.**

**Two rules that keep the future migration cheap.** Both are free if followed from day one:

1. In the custom OS layer, target `.shiki` and `[data-os]`. **Never** `vp-code` or
   `vp-adaptive-theme`; both are removed in v2.
2. Keep theme CSS thin. The reset change is what bites sites with heavy overrides.

---

## 1. Scope

This file covers **architecture and library choices only**.

Requirements (R1–R17), their constraints, and the feature backlog live in
**`requirements.md`**. Requirement IDs referenced below are defined there.

---

## 2. Candidates

| | VitePress | Docusaurus | Astro Starlight | MkDocs Material |
|---|---|---|---|---|
| Stack | Vue 3 + Vite | React + webpack | Astro | Python |
| License | MIT | MIT | MIT | MIT (Insiders = paid tier) |
| R2 SPA nav | ✅ built in | ✅ built in | ⚠️ view transitions, MPA | ⚠️ "instant loading" (XHR) |
| R3 Service worker | ➕ `vite-plugin-pwa` | ✅ `@docusaurus/plugin-pwa` (first-party, Workbox) | ➕ manual / plugin | ❌ DIY workbox-cli |
| R4 OS tabs | ✅ `::: code-group` | ✅ `<Tabs>` | ✅ `<Tabs>` | ✅ content tabs |
| R10 Persist site-wide | ➕ hand-roll (small) | ✅ `groupId` + localStorage | ✅ `syncKey` | ✅ `content.tabs.link` |
| R11 UA detection | ➕ hand-roll, full control | ⚠️ must prime internal storage key | ⚠️ same | ⚠️ same |
| R5 Fuzzy search | ✅ MiniSearch, zero config, real edit-distance | ➕ `@easyops-cn/docusaurus-search-local` | ⚠️ Pagefind: prefix, not typo-tolerant | ⚠️ lunr, weak typo tolerance |
| R7 File embedding | ✅ `<<< @/path#region` native | ➕ `raw-loader` + `<CodeBlock>` | ➕ remark plugin | ✅ `pymdownx.snippets` |
| R9 Batteries | ⚠️ minimal by design | ✅ very | ✅ yes | ✅ very |
| Plugin ecosystem | small | large | growing | large |

✅ native · ➕ one well-supported plugin · ⚠️ partial · ❌ not really

---

## 3. Notes per candidate

### VitePress: *front-runner on search + snippets*
- Stable line is **1.x** (1.6.4). v2 has been in alpha since early 2025, still alpha as of
  July 2026, no stable date. **Use 1.x.**
- Prerenders static HTML per route, then hydrates into a Vue SPA. Prefetches links on
  viewport entry. Best-in-class first paint *and* SPA nav.
- Shiki highlighting (VS Code grammars), diff/focus/error annotations, line highlighting.
- Weaknesses: sidebar must be hand-written or generated via `vitepress-sidebar`
  (community); small plugin ecosystem; **no exact-match search**, since MiniSearch is
  fuzzy by design, a long-standing open request. Tune `fuzzy: 0.1` if flag/package names get noisy.

### Docusaurus: *front-runner on R3 + R9 + R10*
- Only candidate with a **first-party** PWA plugin (Workbox precaching, installable).
- `<Tabs groupId="os">` syncs across the whole page and persists in localStorage,
  solving R10 for free, which VitePress does not.
- No built-in local search; needs the community plugin. Good, not as strong as MiniSearch.
- Heavier build, React/MDX, more config surface.

### Astro Starlight: *rejected*
Best-in-class tab syncing, but Pagefind search is prefix-based rather than typo-tolerant
(fails R5), and file embedding needs a remark plugin (R7 friction).

### MkDocs Material: *rejected*
Good framework, but its `offline` plugin is for shipping `site/` as a **downloadable
folder opened over `file://`**, not browser caching. It also requires disabling instant
loading, so it is mutually exclusive with R2. Real PWA support means hand-gluing
`workbox-cli`: a Python build plus a Node build step. Fails R3 cleanly.

---

## 4. Shortlist

*Historical record of the evaluation. The outcome is §0.*

**Option A: VitePress 1.x** ✅ **chosen**
```
vitepress ~1.6.4        # framework; pin, the 1.x line is frozen (§0)
vite-plugin-pwa         # R3, service worker
vitepress-sidebar       # auto nav from file tree, per locale
+ custom OS layer       # R10/R11, see §4.1
```
Wins on: search quality, snippet imports, build speed, config simplicity, and full
control over the OS layer.

**Option B: Docusaurus**
```
@docusaurus/core
@docusaurus/plugin-pwa            # R3, first-party
@easyops-cn/docusaurus-search-local  # R5
```
Wins on: first-party caching, ecosystem depth.

**Effect of R11 on the decision:** Docusaurus's `groupId` sync was its main edge, but it
delivers persistence only. Auto-detection requires priming the undocumented
`docusaurus.tab.<groupId>` localStorage key from a pre-hydration script, and the
anti-flash script is needed either way. Most of the work happens regardless, so the
free-sync advantage largely evaporates, while VitePress retains the stronger search.

### 4.1 OS layer design (applies to Option A)

Resolution order, first match wins:

1. `?os=` query parameter (shareable links)
2. Stored explicit choice in localStorage
3. Mac check → `macos`
4. **Arch** (default)

Implementation:

- Blocking script injected via the `head` config option → runs the order above, sets
  `document.documentElement.dataset.os`. Must be blocking, or Mac users see a flash.
- A shared `ref` in `.vitepress/theme` as single source of truth, seeded from that
  attribute.
- Custom `<OSTabs>` component, output CSS-controlled by `[data-os]`, wrapping `<<<` file
  imports. **Not** `::: code-group`; the built-in group cannot be styled pre-hydration.
- OS switcher in the **navbar**, required since Debian users get a silent Arch default.
- Writing a choice to localStorage permanently disables step 3.

---

## 5. Repo layout and workflows

Layout keeps executables real, and keeps the two locales next to each other (§7):

```
content/
  en/                    # markdown, source of truth
  de/                    # markdown, translation
  .vitepress/
    config.ts            # locales, search, OS layer
    facts/*.yaml      # locale-neutral documented values (R23/R37)
    theme/               # OS layer; target .shiki and [data-os] only (§0)
scripts/
  arch/ install.sh verify.sh
  debian/ install.sh verify.sh
  macos/ install.sh verify.sh
docker/                  # Dockerfiles, compose files
verifications/           # dated check results (R21)
.github/workflows/
```

Workflows (see `requirements.md` §4.1 for rationale):

| Job | Where | Trigger | Purpose |
|---|---|---|---|
| `lint` | GitHub-hosted | push / PR | shellcheck, hadolint |
| `build-images` | GitHub-hosted | push / PR | build containers (build only, no campus access) |
| `publish` | GitHub-hosted | tag | push multi-arch images to GHCR |
| `deploy` | GitHub-hosted | push to main | build site, deploy to Pages |
| `staleness` | GitHub-hosted | cron | read `verifications/`, open an issue for anything past max age (R21) |
| `fingerprint` | **on-campus prober** | cron | credential-free layer 1–3 checks across all domains → pushes results JSON (R14, R18) |
| `verify-services` | **on-campus prober** | cron | layer 4 checks, *if* a test account is granted |
| macOS check | **human** | periodic | `verify.sh` run by hand, result recorded |
| physical checks | **human** | monthly | layer 5: coded print page, eduroam association, etc. |
| `translations` | GitHub-hosted | push / PR | compare each `content/de/` page's `translatedFrom` hash against its English source; flag stale (R38) |

The prober is a cron job on a campus machine pushing results out over HTTPS, **not** a
self-hosted GitHub Actions runner. It holds **no university credentials** (R20) and
performs unauthenticated observation only. See `requirements.md` §4.1.

Site build notes:

- Set the base path for the repo subdirectory; add `.nojekyll`.
- **Do not precache everything.** Precache app shell + HTML + search index; runtime-cache
  images and large assets.
- Verification results land in a JSON file the site reads at build time, feeding the
  per-page "last verified" badges (R17).
- **Configuration facts** (hostnames, ports, cert fingerprints, share paths) come from a
  YAML data file rendered through a component, never typed into Markdown (R23), and
  shared unchanged by both locales (R37). VitePress `data-loading` covers this at build
  time; the loader also feeds the checks so a value exists exactly once.

---

## 6. Open items (architecture only)

- [x] ~~Pick A or B~~ → **VitePress 1.x** (§0)
- [x] ~~i18n?~~ → **yes, DE + EN**, English is source (§7, R35–R40)
- [ ] Sidebar: hand-written config vs `vitepress-sidebar`, now a per-locale question (§7)
- [ ] Precache budget / runtime-cache split for the service worker: **two search indexes
      now**; decide whether the SW precaches both locales or only the active one
- [ ] Where the verification-results JSON lives and how the site consumes it
- [ ] Translation-staleness check: separate CI job, or fold into the existing `staleness`
      job that already reads `verifications/` (R21)?

Product-level open items are tracked in `requirements.md` §6.

---

## 7. i18n architecture

**English is the source of truth. German is a translation.** One direction only;
bidirectional authoring means two drifting originals and no way to tell which is right.
Contributions in German are welcome; they are translated to English at review, and English
becomes the source from then on.

### 7.1 Layout

```
content/
  en/            # source of truth
    printing/marb-color.md
  de/            # translation
    printing/marb-color.md
  public/
  .vitepress/
    config.ts    # locales: { root: 'en', de: {...} }
    facts/*.yaml     # locale-neutral, shared (R23/R37)
```

Root serves `/en/`; `/de/` is the second locale. VitePress `locales` handles routing,
navbar/sidebar strings and the language switcher. Local search builds **one index per
locale**, so a German query must not surface English hits.

### 7.2 What is never translated

The facts file (R23) is language-neutral and lives once: hostnames, ports, queue names,
share paths, certificate fingerprints, commands, package names. Both locales render the
same values through the same component. **A translated hostname is a bug.**

German UI strings quoted from university systems (form field labels, portal menu paths,
policy document titles) stay verbatim in *both* locales (R36). On the English page they
appear as `„Freischaltung Bereich" (network area)`. A translated form label is a broken
instruction: the reader cannot find it on screen.

Scripts, code comments and commit messages are English-only, in both locales.

### 7.3 Translation staleness

This is the part that matters, and the part AI translation does not solve. A German page
whose English source has changed is *wrong*, and wrongness that nobody can see is the exact
failure mode the whole project exists to prevent: the same problem as campus drift (R14),
in a different dimension.

Mechanism:

- Every file under `content/de/` carries the git blob hash of the English source it was
  translated from, in frontmatter: `translatedFrom: <sha>`.
- A CI job compares that hash against the current source. Mismatch → the page is stale.
- Stale pages render a **banner**, not silence: *"The English source of this page changed
  on <date>. This translation may be out of date."* Serving a stale translation quietly
  is worse than serving English.
- Staleness is reported the same way as unchecked verifications (R21), so there is one
  freshness concept in the project rather than two.

Retranslating is then a cheap, mechanical, batchable job, which is what makes the AI
argument actually hold.
