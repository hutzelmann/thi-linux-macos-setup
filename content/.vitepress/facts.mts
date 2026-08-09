import { readdirSync, readFileSync } from 'node:fs'
import { join, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { parse } from 'yaml'

export const FACTS_DIR = fileURLToPath(new URL('../../facts', import.meta.url))

export type Facts = Record<string, Record<string, string>>

/** Load facts/<domain>.yaml into { domain: { key: value } }. */
export function loadFacts(): Facts {
  const facts: Facts = {}
  for (const file of readdirSync(FACTS_DIR)) {
    if (!file.endsWith('.yaml')) continue
    const domain = basename(file, '.yaml')
    facts[domain] = parse(readFileSync(join(FACTS_DIR, file), 'utf8')) ?? {}
  }
  return facts
}

/** Every fact value, for the consistency check and for substitution. */
export function factEntries(facts: Facts): [string, string][] {
  return Object.entries(facts).flatMap(([domain, keys]) =>
    Object.entries(keys).map(([key, value]) => [`${domain}.${key}`, String(value)] as [string, string])
  )
}

const TOKEN = /\$\{facts\.([a-z0-9_]+)\.([a-z0-9_]+)\}/gi

/**
 * Replace ${facts.domain.key} in markdown source, including inside code fences.
 *
 * Substituting before markdown-it runs is deliberate: a Vue component could not
 * appear inside a fenced block, and the commands people copy are exactly where a
 * stale hostname does the most damage. It also means a page's source never holds
 * the literal value, which is what check-facts.sh asserts.
 */
export function substituteFacts(src: string, facts: Facts, file: string): string {
  return src.replace(TOKEN, (match, domain: string, key: string) => {
    const value = facts[domain]?.[key]
    if (value === undefined) {
      throw new Error(
        `Unknown fact ${match} in ${file}. Add it to facts/${domain}.yaml or fix the reference.`
      )
    }
    return String(value)
  })
}
