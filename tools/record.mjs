#!/usr/bin/env node
/**
 * Record a check you just performed, without going through the issue board.
 *
 * The issue form exists for people who cannot push. A maintainer standing in
 * front of the hardware should not have to file a report to themselves and wait
 * for a robot to answer it, so this is the same applier with a terminal in front
 * of it instead of a workflow.
 *
 * Usage: npm run record -- /en/printing/ [--os=arch] [--commit]
 *
 * Two confirmations, both here: the outcome, which no script can answer, and the
 * diff. Nothing is written before the second one.
 *
 * The date lands under the operating system it was observed on. This machine is
 * the default, since the point of this route is a maintainer standing in front
 * of the hardware, and `--os` is there for the case where that guess is wrong.
 */
import { createInterface } from 'node:readline/promises'
import { stdin, stdout } from 'node:process'
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join, relative } from 'node:path'
import { spawnSync } from 'node:child_process'
import {
  ROOT,
  OS_IDS,
  resolvePage,
  isCheckable,
  declaredOs,
  languagePair,
  readKey,
  readMap,
  blobSha,
  applyCheck,
  normaliseOs,
  normaliseDate
} from './check-record.mjs'

/**
 * Which of the documented systems this is, or null.
 *
 * Same three-way split as `detect_os` in scripts/lib/common.sh, and for the same
 * reason: those are the systems the pages have blocks for. Anything else is a
 * machine whose steps nobody wrote down, and guessing one for it would put a
 * date on a block it was never run against.
 */
function detectOs() {
  if (process.platform === 'darwin') return 'macos'
  if (process.platform !== 'linux') return null

  try {
    const release = readFileSync('/etc/os-release', 'utf8')
    const field = (key) =>
      (release.match(new RegExp(`^${key}=(.*)$`, 'm'))?.[1] ?? '').replace(/"/g, '')
    const id = `${field('ID')} ${field('ID_LIKE')}`.toLowerCase()
    if (id.includes('arch')) return 'arch'
    if (id.includes('debian') || id.includes('ubuntu')) return 'debian'
  } catch {
    // No /etc/os-release is answer enough: this is not one of the three.
  }
  return null
}

/**
 * The verify script that covers a page, if there is one.
 *
 * Read out of the scripts themselves rather than kept in a table here: the
 * scripts already declare the page they belong to for `--report`, and a second
 * copy of that mapping is a second thing to forget.
 */
function scriptFor(page) {
  const dir = join(ROOT, 'scripts')
  for (const area of readdirSync(dir)) {
    const candidate = join(dir, area, 'verify.sh')
    if (!existsSync(candidate)) continue
    const declared = readFileSync(candidate, 'utf8').match(/^REPORT_PAGE=(.+)$/m)
    if (declared && resolveQuietly(declared[1].trim()) === page) return candidate
  }
  return null
}

function resolveQuietly(input) {
  try {
    return resolvePage(input)
  } catch {
    return null
  }
}

/** What applyCheck would do, worked out without doing any of it. */
function preview(path, date, os) {
  const pair = languagePair(path)
  const rows = []
  if (!pair.en) return rows

  const recorded = pair.de ? readKey(pair.de, 'translatedFrom') : null
  const stale = Boolean(pair.de) && recorded !== blobSha(pair.en)
  const targets = stale ? [path] : [pair.en, pair.de].filter(Boolean)

  for (const target of targets) {
    const current = readMap(target, 'lastChecked')[os]
    rows.push({
      file: relative(ROOT, target),
      change: current
        ? `~ lastChecked.${os}: ${current} -> ${date}`
        : `+ lastChecked.${os}: ${date}`
    })
  }
  if (!stale && pair.de) {
    rows.push({
      file: relative(ROOT, pair.de),
      change: `~ translatedFrom: ${String(recorded).slice(0, 7)} -> (recomputed)`
    })
  }
  if (stale) {
    rows.push({
      file: relative(ROOT, pair.de),
      change: 'unchanged: out of date with its English source, so the check stops here'
    })
  }
  return rows
}

/**
 * The local calendar day.
 *
 * Not the UTC day: this records when a person did something, and somebody
 * working late in Ingolstadt has already turned the page on the calendar in
 * front of them while UTC has not. The date they would write down is the one
 * that goes in the file.
 */
function today() {
  const now = new Date()
  const pad = (n) => String(n).padStart(2, '0')
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
}

/**
 * Ask, and treat a closed input as a refusal.
 *
 * `question` never settles once stdin ends, which turns a piped or backgrounded
 * run into a process that hangs holding a half-applied intention. Declining is
 * the safe reading of "no answer".
 */
async function ask(rl, prompt) {
  const answered = rl.question(prompt)
  // Deferred a tick: at end of input both the buffered answer and the close
  // event are ready at once, and an answer the user actually gave must win.
  const closed = new Promise((resolve) => {
    rl.once('close', () => setImmediate(() => resolve(null)))
  })
  const answer = await Promise.race([answered, closed])
  return answer === null ? '' : answer.trim().toLowerCase()
}

async function main() {
  const args = process.argv.slice(2)
  const commit = args.includes('--commit')
  const target = args.find((a) => !a.startsWith('--'))
  const requested = args.find((a) => a.startsWith('--os='))?.slice('--os='.length)

  if (!target) {
    console.error('Usage: npm run record -- /en/printing/ [--os=arch] [--commit]')
    return 2
  }

  let path
  try {
    path = resolvePage(target)
  } catch (error) {
    console.error(error.message)
    return 1
  }

  if (!isCheckable(path)) {
    console.error(
      `${relative(ROOT, path)} declares no os: block, so it has no steps to run and`
        + ' shows "nothing to check here". There is nothing to record.'
    )
    return 1
  }

  const os = requested ? normaliseOs(requested) : detectOs()
  if (!os) {
    console.error(
      requested
        ? `"${requested}" is not one of ${OS_IDS.join(', ')}.`
        : 'This machine is not one of the systems the pages document, so there is no'
          + ` block a date could belong to. Pass --os=<${OS_IDS.join('|')}> if you are`
          + ' recording a run from elsewhere.'
    )
    return 1
  }

  const declared = declaredOs(path)
  if (!declared.includes(os)) {
    console.error(
      `${relative(ROOT, path)} declares os: [${declared.join(', ')}] and has no ${os}`
        + ' block, so there are no steps there to have followed.'
    )
    return 1
  }

  const script = scriptFor(path)
  if (script) {
    console.log(`Running ${relative(ROOT, script)}\n`)
    // Its exit code is information, not a gate. Several of these check something
    // narrower than the page covers, so a failure here is worth seeing and worth
    // overriding; what it must not do is pass unnoticed.
    spawnSync('sh', [script], { cwd: ROOT, stdio: 'inherit' })
    console.log()
  } else {
    console.log(`No verify script covers ${relative(ROOT, path)}. Recording by hand.\n`)
  }

  const rl = createInterface({ input: stdin, output: stdout })
  try {
    // The OS is named in the question rather than only in the diff. It is the
    // whole scope of what is about to be claimed, and the other two blocks on
    // the page stay exactly as unchecked as they were.
    const outcome = await ask(
      rl,
      `Did the ${os} steps on this page, followed as written, get you here?`
        + ' [y/adjusted/n] '
    )

    if (outcome !== 'y' && outcome !== 'yes') {
      console.log(
        '\nNot recorded. A date here would claim a check nobody performed.\n'
          + 'Fix the page first, then record a check against the fixed steps.'
      )
      return 0
    }

    const date = normaliseDate(today())
    const rows = preview(path, date, os)
    if (!rows.length) {
      console.log('Nothing to change.')
      return 0
    }

    console.log()
    for (const row of rows) console.log(`  ${row.file}\n    ${row.change}`)
    console.log()

    const go = await ask(rl, 'Apply? [y/N] ')
    if (go !== 'y' && go !== 'yes') {
      console.log('Nothing written.')
      return 0
    }

    const applied = applyCheck({ path, date, os })
    for (const file of applied.touched) console.log(`updated ${file}`)
    for (const note of applied.notes) console.log(`\n${note}`)

    const message = `Record ${os} check of ${target} (${date})`
    if (commit) {
      spawnSync('git', ['commit', '-m', message, '--', ...applied.touched], {
        cwd: ROOT,
        stdio: 'inherit'
      })
      return 0
    }

    console.log('\nReview and commit:')
    console.log('  git diff')
    console.log(`  git commit -m ${JSON.stringify(message)} -- ${applied.touched.join(' ')}`)
    return 0
  } finally {
    rl.close()
  }
}

process.exit(await main())
