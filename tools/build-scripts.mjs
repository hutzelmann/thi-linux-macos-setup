#!/usr/bin/env node
/**
 * Bundle each script into a standalone file that runs without a clone.
 *
 * In the repository, scripts source scripts/lib/*.sh and read facts/*.yaml by
 * walking up the tree. That is right for maintenance (one copy of the helpers,
 * one copy of every documented value) and useless to a reader who arrived from
 * a search result with a broken printer. They need one file they can download,
 * read, and run.
 *
 * So the shipped artifact is generated: helpers inlined, documented values baked
 * in as a generated `fact()` lookup. The source scripts stay unchanged and keep
 * calling `fact printing queue`, so there is still exactly one place a hostname
 * is written down. Regenerated on every build, so it cannot drift from facts/.
 *
 * Output: content/public/scripts/<domain>-<name>.sh
 * Served at: <base>/scripts/<domain>-<name>.sh
 */
import { readdirSync, readFileSync, writeFileSync, mkdirSync, rmSync, statSync } from 'node:fs'
import { join, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { parse } from 'yaml'

const ROOT = fileURLToPath(new URL('..', import.meta.url))
const SCRIPTS = join(ROOT, 'scripts')
const FACTS = join(ROOT, 'facts')
const OUT = join(ROOT, 'content/public/scripts')

const SITE = 'https://hutzelmann.github.io/thi-linux-macos-setup/'

/** Every documented value, flattened to "domain.key". */
function loadFacts() {
  const entries = []
  for (const file of readdirSync(FACTS)) {
    if (!file.endsWith('.yaml')) continue
    const domain = basename(file, '.yaml')
    const data = parse(readFileSync(join(FACTS, file), 'utf8')) ?? {}
    for (const [key, value] of Object.entries(data)) {
      entries.push([`${domain} ${key}`, String(value)])
    }
  }
  return entries
}

/**
 * A generated stand-in for scripts/lib/facts.sh with the values already in it.
 * Same interface, `fact <domain> <key>`, so nothing in the script changes.
 */
function generateFactFunction(entries) {
  const cases = entries
    .map(([id, value]) => {
      // Single quotes inside a single-quoted shell string.
      const safe = value.replace(/'/g, `'\\''`)
      return `    '${id}') printf '%s\\n' '${safe}' ;;`
    })
    .join('\n')

  return `# --- documented values, baked in at build time ----------------------------
# Generated from facts/*.yaml. Do not edit here: change the value in that
# repository and the next build regenerates this file.
#
# fact_env is consulted first, exactly as scripts/lib/facts.sh does it, so a
# downloaded script honours FACT_<DOMAIN>_<KEY> like the repository one and a
# substituted value shows up in the result either way.
fact() {
  if fact_env "$1" "$2"; then
    return 0
  fi

  case "$1 $2" in
${cases}
    *) echo "unknown fact: $1 $2" >&2; return 1 ;;
  esac
}
`
}

function stripShebang(source) {
  return source.replace(/^#!.*\n/, '')
}

/** Remove the lines that only exist to locate the shared helpers. */
function stripSourcing(source) {
  return source
    .split('\n')
    .filter(
      (line) =>
        !/^DIR=\$\(CDPATH=/.test(line) &&
        !/^\.\s+"\$DIR\/\.\.\/lib\//.test(line) &&
        !/^# shellcheck source=\.\.\/lib\//.test(line)
    )
    .join('\n')
}

/**
 * Drop shellcheck directives and the comments that explain them.
 *
 * They address the repository layout, where the helpers are separate files that
 * shellcheck reads one at a time. In the bundle everything is one file, so the
 * directive is both unnecessary and a distraction to a reader who came here to
 * see what the script does before running it.
 */
function stripLintDirectives(source) {
  const lines = source.split('\n')
  const out = []
  for (let i = 0; i < lines.length; i++) {
    if (!/^# shellcheck /.test(lines[i])) {
      out.push(lines[i])
      continue
    }
    // Also drop the comment block immediately above it, which exists only to
    // explain the directive.
    while (out.length && /^#( |$)/.test(out[out.length - 1])) out.pop()
  }
  return out.join('\n')
}

function header(relative) {
  return `#!/usr/bin/env sh
#
# ${relative}: standalone copy
#
# Generated from ${SITE}
# Community-maintained and unofficial. Not THI IT Support. No warranty.
#
# Read it before running it. Every script here supports --dry-run, which prints
# what it would do and changes nothing.
#
# Released into the public domain under CC0 1.0.
`
}

function main() {
  const facts = loadFacts()
  const common = stripLintDirectives(stripShebang(readFileSync(join(SCRIPTS, 'lib/common.sh'), 'utf8')))
  const factsLib = stripLintDirectives(stripShebang(readFileSync(join(SCRIPTS, 'lib/facts.sh'), 'utf8')))

  rmSync(OUT, { recursive: true, force: true })
  mkdirSync(OUT, { recursive: true })

  const built = []

  for (const domain of readdirSync(SCRIPTS)) {
    const domainDir = join(SCRIPTS, domain)
    if (domain === 'lib' || domain === 'ci' || !statSync(domainDir).isDirectory()) continue

    for (const file of readdirSync(domainDir)) {
      if (!file.endsWith('.sh')) continue

      const source = readFileSync(join(domainDir, file), 'utf8')
      const body = stripSourcing(stripShebang(source))
      const name = `${domain}-${file}`

      const bundle = [
        header(`scripts/${domain}/${file}`),
        generateFactFunction(facts),
        '# --- shared helpers -------------------------------------------------------',
        common.trim(),
        '',
        '# --- documented values, and running against something else --------------------',
        factsLib.trim(),
        '',
        '# --- script ---------------------------------------------------------------',
        body.trim(),
        ''
      ].join('\n')

      writeFileSync(join(OUT, name), bundle, { mode: 0o755 })
      built.push(`${name} (${bundle.split('\n').length} lines)`)
    }
  }

  console.log(`Bundled ${built.length} standalone script(s):`)
  for (const b of built) console.log(`  ${b}`)
}

main()
