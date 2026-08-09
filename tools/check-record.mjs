#!/usr/bin/env node
/**
 * Turn a check record into the one frontmatter field that records it.
 *
 * A page is checked exactly when it carries `lastChecked`. Somebody has to put
 * that date there, and until now nothing did: the issue form collected reports
 * and no code read them, so the evidence and the claim were connected by
 * whoever happened to remember. This is that connection, written down once and
 * shared by every route into it.
 *
 * `lastChecked` is a map keyed by operating system, never a single date:
 *
 *   lastChecked:
 *     arch: 2026-08-08
 *     macos: 2026-05-01
 *
 * Every page here declares `os: [arch, debian, macos]` and forks its steps three
 * ways, so one date across all of them would claim two checks nobody performed.
 * A run on Arch says nothing about the macOS block, and the form has always
 * asked which machine it was; that answer now reaches the page instead of
 * stopping at the issue.
 *
 * Three front ends call the same three functions:
 *
 *   .github/workflows/check-record.yml   --body-file=  (an issue becomes a PR)
 *   tools/record.mjs                     --page= --date=  (a maintainer, locally)
 *   a maintainer with a filed issue      --issue=  (needs the gh CLI)
 *
 * Nothing here writes prose. The only thing that reaches a page is an ISO date,
 * which is why an untrusted issue body can drive it at all.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

export const ROOT = fileURLToPath(new URL('..', import.meta.url))

/**
 * Field labels as the issue form renders them.
 *
 * GitHub writes the field's *label*, not its id, as a heading. So this map has
 * to track .github/ISSUE_TEMPLATE/check-record.yml by hand. A label that drifts
 * shows up as a missing field rather than a wrong one, which the workflow
 * reports rather than guessing around.
 */
const LABELS = {
  'which page': 'page',
  'what did you run it on': 'os',
  version: 'version',
  'date you did this': 'date',
  'how did it go': 'outcome',
  'what differed, if anything': 'notes',
  'script output': 'report'
}

/** The one outcome that may put a date on a page. */
export const CLEAN_PASS = 'Worked exactly as written'

/**
 * Operating systems a page can declare, in the order the switcher shows them.
 *
 * Also the order `lastChecked` is written in, so the map reads the same way on
 * every page and a diff never reorders lines nobody touched.
 */
export const OS_IDS = ['arch', 'debian', 'macos']

/**
 * The issue form's dropdown labels, mapped onto those ids.
 *
 * Tracks the `os` options in .github/ISSUE_TEMPLATE/check-record.yml by hand,
 * for the same reason LABELS above does. "Other Linux" maps to nothing on
 * purpose: the pages have no block for it, so a date from one would be a claim
 * about steps that were never written down.
 */
const OS_LABELS = {
  'arch linux': 'arch',
  'debian / ubuntu': 'debian',
  'debian/ubuntu': 'debian',
  macos: 'macos',
  'other linux': null
}

/**
 * An os id out of whatever the record carried, or null.
 *
 * Two shapes arrive here: the dropdown label a person picked, and the bare id
 * `verify.sh --json` prints from `detect_os`. Both are accepted so the typed
 * field and the script output cannot disagree about what they mean.
 */
export function normaliseOs(value) {
  if (!value) return null
  const raw = String(value).trim().toLowerCase()
  if (OS_IDS.includes(raw)) return raw
  if (raw in OS_LABELS) return OS_LABELS[raw]
  return null
}

/**
 * Split a rendered issue-form body into its fields.
 *
 * The rendering is stable: `### <label>`, a blank line, the value, and the
 * literal `_No response_` where an optional field was left empty. Fields
 * declared `render: shell` arrive wrapped in a fence, which is stripped here so
 * callers see the payload and not the presentation.
 */
export function parseIssueBody(body) {
  const fields = {}
  const sections = String(body).split(/^###[ \t]+/m).slice(1)

  for (const section of sections) {
    const newline = section.indexOf('\n')
    if (newline === -1) continue
    const label = section.slice(0, newline).trim().toLowerCase()
    const key = LABELS[label]
    if (!key) continue

    let value = section.slice(newline + 1).trim()
    if (value === '_No response_' || value === '') {
      fields[key] = null
      continue
    }
    const fenced = value.match(/^```[a-z]*\n([\s\S]*?)\n?```$/)
    if (fenced) value = fenced[1].trim()
    fields[key] = value
  }

  return fields
}

/**
 * Read what the verify script observed.
 *
 * Preferred over the typed fields wherever both exist: this came out of
 * `verify.sh --json`, already stripped of identifiers by `redact()`, and cannot
 * be mistyped. It is still only evidence about the machine. Whether the page's
 * steps are what produced that machine is the question the form asks a human.
 */
export function parseReport(json) {
  if (!json) return {}
  let data
  try {
    data = JSON.parse(json)
  } catch {
    // A contributor pasting something else in is not an error worth stopping
    // for; the typed fields still carry the record.
    return {}
  }
  const out = {}
  if (typeof data.os === 'string') out.os = data.os
  if (typeof data.page === 'string') out.page = data.page
  if (typeof data.date === 'string') out.date = data.date
  return out
}

/** ISO day, or null. Rejects anything that would poison the staleness horizon. */
export function normaliseDate(value, today = new Date()) {
  if (!value) return null
  const match = String(value).trim().match(/^(\d{4}-\d{2}-\d{2})/)
  if (!match) return null
  const day = match[1]

  const parsed = new Date(`${day}T00:00:00Z`)
  if (Number.isNaN(parsed.getTime())) return null
  if (parsed.toISOString().slice(0, 10) !== day) return null

  // A future date is a typo, and it would sit at the top of the status page
  // claiming to be the freshest check in the repository.
  //
  // The ceiling is tomorrow, not today. Dates here are the local calendar day a
  // person did the work, and the workflow that checks them runs in UTC. Someone
  // in Ingolstadt reporting at half past midnight is a day ahead of the runner,
  // and rejecting them would be a bug that only appears at night.
  const now = new Date(today.toISOString().slice(0, 10) + 'T00:00:00Z')
  const ceiling = new Date(now)
  ceiling.setUTCDate(ceiling.getUTCDate() + 1)
  if (parsed > ceiling) return null

  // Two years is not a rule about when a check expires, only a bound on what
  // could plausibly be a real run somebody is reporting now.
  const floor = new Date(now)
  floor.setUTCFullYear(floor.getUTCFullYear() - 2)
  if (parsed < floor) return null

  return day
}

/** Frontmatter as lines, with the index of its closing fence. */
function frontmatter(text) {
  const lines = text.split('\n')
  if (lines[0] !== '---') return null
  const end = lines.indexOf('---', 1)
  if (end === -1) return null
  return { lines, end }
}

/** One scalar value out of a page's frontmatter, unparsed. */
export function readKey(path, key) {
  const fm = frontmatter(readFileSync(path, 'utf8'))
  if (!fm) return null
  for (let i = 1; i < fm.end; i++) {
    const match = fm.lines[i].match(new RegExp(`^${key}:\\s*(.*)$`))
    if (match) return match[1].trim().replace(/^"(.*)"$/, '$1')
  }
  return null
}

/**
 * A nested block of `  key: value` lines out of frontmatter, as an object.
 *
 * Returns `{}` both when the key is absent and when it holds a scalar. Callers
 * that need to tell those apart ask `readKey` as well: a scalar `lastChecked`
 * is a page written against the old single-date shape, and silently reading it
 * as empty would let a check be recorded over the top of one already claimed.
 */
export function readMap(path, key) {
  const fm = frontmatter(readFileSync(path, 'utf8'))
  if (!fm) return {}

  const out = {}
  for (let i = 1; i < fm.end; i++) {
    if (fm.lines[i].trim() !== `${key}:`) continue
    for (let j = i + 1; j < fm.end; j++) {
      const entry = fm.lines[j].match(/^\s+([A-Za-z0-9_-]+):\s*(.*)$/)
      if (!entry) break
      out[entry[1]] = entry[2].trim().replace(/^"(.*)"$/, '$1')
    }
    break
  }
  return out
}

/**
 * Set one entry inside a nested frontmatter key, in place.
 *
 * The block is rewritten whole rather than patched line by line, so entries
 * stay in `order` no matter which route wrote them and a second record never
 * produces a diff that also shuffles the first. Same line-based approach as
 * setKey below, and for the same reason: a YAML round trip would reorder keys
 * and drop the comments several pages carry.
 */
export function setMapEntry(path, key, entryKey, value, { order = OS_IDS } = {}) {
  const text = readFileSync(path, 'utf8')
  const fm = frontmatter(text)
  if (!fm) throw new Error(`No frontmatter in ${relative(ROOT, path)}`)

  let start = -1
  for (let i = 1; i < fm.end; i++) {
    if (fm.lines[i].startsWith(`${key}:`)) {
      if (fm.lines[i].trim() !== `${key}:`) {
        throw new Error(
          `${relative(ROOT, path)} has a scalar ${key}. It is a map keyed by`
            + ' operating system now, so this page has to be converted before a'
            + ' check can be recorded against it.'
        )
      }
      start = i
      break
    }
  }

  const entries = start === -1 ? {} : readMap(path, key)
  if (entries[entryKey] === String(value)) return false
  entries[entryKey] = String(value)

  const rank = (id) => {
    const at = order.indexOf(id)
    return at === -1 ? order.length : at
  }
  const block = [
    `${key}:`,
    ...Object.keys(entries)
      .sort((a, b) => rank(a) - rank(b) || a.localeCompare(b))
      .map((id) => `  ${id}: ${entries[id]}`)
  ]

  if (start === -1) {
    let at = 1
    for (let i = 1; i < fm.end; i++) {
      if (fm.lines[i].startsWith('title:')) {
        at = i + 1
        break
      }
    }
    fm.lines.splice(at, 0, ...block)
  } else {
    let stop = start + 1
    while (stop < fm.end && /^\s+[A-Za-z0-9_-]+:/.test(fm.lines[stop])) stop++
    fm.lines.splice(start, stop - start, ...block)
  }

  writeFileSync(path, fm.lines.join('\n'))
  return true
}

/**
 * Set one frontmatter key, in place, without reserialising.
 *
 * Deliberately line-based. Round-tripping through a YAML library reorders keys
 * and drops the comments several pages carry, which would turn a one-line date
 * change into a diff nobody can review. New keys land after `title`, where the
 * page contract shows them.
 */
export function setKey(path, key, value) {
  const text = readFileSync(path, 'utf8')
  const fm = frontmatter(text)
  if (!fm) throw new Error(`No frontmatter in ${relative(ROOT, path)}`)

  const line = `${key}: ${value}`
  for (let i = 1; i < fm.end; i++) {
    if (fm.lines[i].startsWith(`${key}:`)) {
      if (fm.lines[i] === line) return false
      fm.lines[i] = line
      writeFileSync(path, fm.lines.join('\n'))
      return true
    }
  }

  let at = 1
  for (let i = 1; i < fm.end; i++) {
    if (fm.lines[i].startsWith('title:')) {
      at = i + 1
      break
    }
  }
  fm.lines.splice(at, 0, line)
  writeFileSync(path, fm.lines.join('\n'))
  return true
}

/** What git records for a file's current contents. */
export function blobSha(path) {
  return execFileSync('git', ['hash-object', relative(ROOT, path)], {
    cwd: ROOT,
    encoding: 'utf8'
  }).trim()
}

/**
 * Resolve what a contributor typed onto exactly one page.
 *
 * Accepts what people actually paste: a site path, a path with the base prefix,
 * a full URL, a repository path. It never guesses between candidates, because a
 * date written onto the wrong page is worse than a report that bounced.
 */
export function resolvePage(input) {
  if (!input) throw new Error('No page given.')

  let p = String(input).trim()
  p = p.replace(/^https?:\/\/[^/]+/, '')
  p = p.replace(/^\/thi-linux-macos-setup/, '')
  p = p.replace(/[?#].*$/, '')
  p = p.replace(/^\/+/, '').replace(/^content\//, '')

  const candidates = [
    p.endsWith('.md') ? p : null,
    `${p.replace(/\/$/, '')}.md`,
    `${p.replace(/\/$/, '')}/index.md`
  ].filter(Boolean)

  for (const candidate of candidates) {
    const full = join(ROOT, 'content', candidate)
    if (existsSync(full)) return full
  }

  throw new Error(
    `No page matches "${input}". Tried:\n`
      + candidates.map((c) => `  content/${c}`).join('\n')
  )
}

/**
 * The same page in the other language, if it exists.
 *
 * The two locales mirror each other path for path, which is the property that
 * lets the translation check, the language switcher and this all work by
 * swapping one segment.
 */
export function languagePair(path) {
  const rel = relative(join(ROOT, 'content'), path)
  const locale = rel.slice(0, 2)
  if (locale !== 'en' && locale !== 'de') return { locale: null, en: path, de: null }

  const other = locale === 'en' ? 'de' : 'en'
  const otherPath = join(ROOT, 'content', other + rel.slice(2))
  const exists = existsSync(otherPath)

  return locale === 'en'
    ? { locale, en: path, de: exists ? otherPath : null }
    : { locale, en: exists ? otherPath : null, de: path }
}

/**
 * Record a check on a page and on its translation.
 *
 * A check confirms a procedure, not a piece of prose. Both languages take their
 * hostnames and queue names from the same `facts/` entries and are followed
 * with the same script, so a record filed against either covers both.
 *
 * That holds exactly as far as `check-translations.sh` holds: the recorded blob
 * sha matching the English source is the mechanical guarantee that the German
 * page still describes the same procedure. When that guarantee is already
 * broken the German page may have moved on from what was checked, so the stamp
 * stops at the page it was filed against and says why.
 *
 * It does not carry across operating systems. Both languages describe the same
 * three OS blocks, and a run on one of them is evidence about that one.
 */
export function applyCheck({ path, date, os }) {
  const pair = languagePair(path)
  const touched = []
  const notes = []

  if (!OS_IDS.includes(os)) {
    throw new Error(`applyCheck needs one of ${OS_IDS.join(', ')}, got "${os}".`)
  }

  if (!pair.en) {
    throw new Error(
      `${relative(ROOT, path)} has no English source. English is the source of truth;`
        + ' check-translations.sh already fails on this.'
    )
  }

  const recorded = pair.de ? readKey(pair.de, 'translatedFrom') : null
  const staleMirror = Boolean(pair.de) && recorded !== blobSha(pair.en)

  const order = declaredOs(pair.en)
  const targets = staleMirror ? [path] : [pair.en, pair.de].filter(Boolean)
  for (const target of targets) {
    if (setMapEntry(target, 'lastChecked', os, date, { order })) {
      touched.push(relative(ROOT, target))
    }
  }

  if (staleMirror) {
    notes.push(
      `${relative(ROOT, pair.de)} is out of date with its English source, so the check`
        + ' was not carried across. Retranslate it, then record a check against it.'
    )
  } else if (pair.de) {
    // Taken last and written only into the German file, so the English sha this
    // records cannot move again as a result of recording it.
    const sha = blobSha(pair.en)
    if (setKey(pair.de, 'translatedFrom', sha)) {
      const rel = relative(ROOT, pair.de)
      if (!touched.includes(rel)) touched.push(rel)
    }
  }

  return { touched, notes, staleMirror }
}

/**
 * Which operating systems a page has blocks for, as declared in `os:`.
 *
 * The list is the whole scope of what can be checked on that page: a record for
 * an OS it does not document has nowhere to render and nothing to describe.
 */
export function declaredOs(path) {
  const raw = readKey(path, 'os')
  if (raw === null) return []
  return raw
    .replace(/^\[/, '')
    .replace(/\]$/, '')
    .split(',')
    .map((entry) => entry.trim().replace(/^"(.*)"$/, '$1'))
    .filter(Boolean)
}

/** A page is in scope for checking when it has steps to run on a machine. */
export function isCheckable(path) {
  return declaredOs(path).length > 0
}

function fetchIssue(number) {
  const raw = execFileSync(
    'gh',
    ['issue', 'view', String(number), '--json', 'body,title,number'],
    { cwd: ROOT, encoding: 'utf8' }
  )
  return JSON.parse(raw)
}

/**
 * Everything a caller needs to decide, without deciding it for them.
 *
 * Returns `applied: false` with a reason rather than throwing, so the workflow
 * can turn a refusal into a comment instead of a failed run. A record that
 * cannot be applied is still a useful report, and losing it in a red X would
 * teach contributors that reporting does not work.
 */
export function evaluate(fields, { today = new Date() } = {}) {
  const merged = { ...fields, ...parseReport(fields.report) }
  const date = normaliseDate(fields.date ?? merged.date, today)

  if (!date) {
    return { applied: false, reason: `Date "${fields.date ?? ''}" is not a usable ISO date.` }
  }

  let path
  try {
    path = resolvePage(merged.page ?? fields.page)
  } catch (error) {
    return { applied: false, reason: error.message }
  }

  if (!isCheckable(path)) {
    return {
      applied: false,
      path,
      date,
      reason:
        `${relative(ROOT, path)} declares no os: block, so it has nothing to check`
        + ' and shows "nothing to check here". A date on it would render nowhere.'
    }
  }

  if (fields.outcome !== CLEAN_PASS) {
    return {
      applied: false,
      path,
      date,
      needsPageFix: true,
      reason:
        `Outcome was "${fields.outcome ?? 'not given'}", so the steps as written did not`
        + ' work. A date here would claim a check nobody performed. The page needs'
        + ' fixing first.'
    }
  }

  // Last, because it is the only refusal that is about the reporter's machine
  // rather than the report. Getting the other reasons first keeps the reply
  // useful to someone who also picked the wrong page or mistyped the date.
  const os = normaliseOs(fields.os ?? merged.os)
  if (!os) {
    return {
      applied: false,
      path,
      date,
      reason:
        `"${fields.os ?? 'not given'}" is not an operating system this page has a block`
        + ` for. A date is recorded per OS, one of ${OS_IDS.join(', ')}, because a run on`
        + ' one says nothing about the others. Other Linux has no block to check against.'
    }
  }

  const declared = declaredOs(path)
  if (!declared.includes(os)) {
    return {
      applied: false,
      path,
      date,
      os,
      reason:
        `${relative(ROOT, path)} declares os: [${declared.join(', ')}] and has no ${os}`
        + ' block, so there are no steps there that this run could have followed.'
    }
  }

  return { applied: true, path, date, os }
}

function usage() {
  return `Usage:
  node tools/check-record.mjs --body-file=PATH            an issue body on disk
  node tools/check-record.mjs --issue=N                   fetch issue N with the gh CLI
  node tools/check-record.mjs --page=P --os=O --date=D    apply directly

Options:
  --os        one of ${OS_IDS.join(', ')}; a date is recorded per operating system
  --dry-run   report what would change, write nothing
  --json      machine-readable result`
}

function main(argv) {
  const args = Object.fromEntries(
    argv.filter((a) => a.startsWith('--')).map((a) => {
      const [k, ...v] = a.replace(/^--/, '').split('=')
      return [k, v.length ? v.join('=') : true]
    })
  )
  const json = Boolean(args.json)
  const dryRun = Boolean(args['dry-run'])

  let fields
  let issue = null
  if (args['body-file']) {
    fields = parseIssueBody(readFileSync(args['body-file'], 'utf8'))
  } else if (args.issue) {
    issue = fetchIssue(args.issue)
    fields = parseIssueBody(issue.body ?? '')
  } else if (args.page) {
    fields = { page: args.page, date: args.date, os: args.os, outcome: CLEAN_PASS }
  } else {
    console.error(usage())
    return 2
  }

  const result = evaluate(fields)
  const emit = (payload) => {
    if (json) console.log(JSON.stringify(payload))
    return payload
  }

  if (!result.applied) {
    const { path, ...rest } = result
    emit({
      ...rest,
      page: path ? relative(ROOT, path) : null,
      issue: issue?.number ?? null
    })
    if (!json) console.error(`Not applied: ${result.reason}`)
    return result.needsPageFix ? 3 : 1
  }

  if (dryRun) {
    emit({
      applied: false,
      dryRun: true,
      page: relative(ROOT, result.path),
      date: result.date,
      os: result.os
    })
    if (!json) {
      console.log(
        `Would set lastChecked.${result.os}: ${result.date}`
          + ` on ${relative(ROOT, result.path)}`
      )
    }
    return 0
  }

  const applied = applyCheck(result)
  emit({
    applied: true,
    page: relative(ROOT, result.path),
    date: result.date,
    os: result.os,
    issue: issue?.number ?? null,
    ...applied
  })
  if (!json) {
    for (const file of applied.touched) console.log(`updated ${file}`)
    for (const note of applied.notes) console.log(note)
    if (!applied.touched.length) console.log('Nothing to change; that date is already recorded.')
  }
  return 0
}

// Guarded so the functions above can be imported and exercised one at a time,
// the same shape the shell scripts use.
if (process.argv[1] && process.argv[1].endsWith('check-record.mjs')) {
  process.exit(main(process.argv.slice(2)))
}
