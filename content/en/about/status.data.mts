import { createContentLoader } from 'vitepress'

export interface PageStatusRow {
  url: string
  title: string
  /** Which operating systems this page has blocks for, as declared in `os:`. */
  os: string[]
  /** Date per operating system, null where nobody has run those steps. */
  checked: Record<string, string | null>
  locale: 'en' | 'de'
}

/**
 * The needs-love board is generated, never hand-written: a hand-maintained list
 * of what needs work is itself a thing that needs work, and it goes stale first.
 *
 * The unit is a page and an operating system, not a page. Every page here forks
 * its steps three ways and `lastChecked` is a map keyed by the system the run
 * happened on, so a page current on Arch and untouched on macOS shows as both
 * rather than as one averaged verdict.
 *
 * There is still no field declaring a state. A page is checked, for one system,
 * exactly when it carries a date for it, so verification cannot be claimed
 * without saying when it happened. Pages are in scope when they declare `os`,
 * because a page with no steps to run on a machine has nothing to check.
 *
 * The order is the setup order, read off the new-machine page rather than
 * written out here. Somebody reordering the setup reorders this with it, and a
 * second copy of that sequence is a second thing to forget. It also means the
 * table does not reshuffle every time a check is recorded, which a
 * least-covered-first sort did.
 */

/*
 * An unquoted YAML date arrives as a Date. Only the day was ever meant, and the
 * table prints the value verbatim.
 */
function day(value: unknown): string | null {
  if (!value) return null
  if (value instanceof Date) return value.toISOString().slice(0, 10)
  return String(value).slice(0, 10)
}

/** The recorded dates, keyed by os id, ignoring anything not in `os:`. */
function checkedPerOs(value: unknown, os: string[]): Record<string, string | null> {
  const map =
    value && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {}
  return Object.fromEntries(os.map((id) => [id, day(map[id])]))
}

/** One comparable form, so a link and a page url can be matched. */
function normalise(url: string): string {
  return url
    .replace(/[?#].*$/, '')
    .replace(/\.html$/, '')
    .replace(/\/$/, '')
}

/** The English page a row belongs to, so both boards share one order. */
function englishUrl(url: string): string {
  return normalise(url).replace(/^\/de\//, '/en/')
}

/**
 * Internal links in the order the setup page makes them, deduplicated.
 *
 * The setup page is the sequence somebody actually works through, so it is the
 * order this table is most useful in. Reading it out of the page keeps the two
 * from drifting; a page nobody links from there sorts to the end.
 */
function setupOrder(source: string | undefined): string[] {
  if (!source) return []
  const seen: string[] = []
  for (const match of source.matchAll(/\]\((\/[^)\s]+)\)/g)) {
    const url = normalise(match[1])
    if (!seen.includes(url)) seen.push(url)
  }
  return seen
}

const SETUP_PAGE = '/en/start/new-machine'

export default createContentLoader('*/**/*.md', {
  // Only to read the setup page's link order. Nothing here reaches the payload.
  includeSrc: true,
  transform(raw): PageStatusRow[] {
    const order = setupOrder(
      raw.find((page) => normalise(page.url) === SETUP_PAGE)?.src
    )
    const rank = (url: string) => {
      const at = order.indexOf(englishUrl(url))
      return at === -1 ? order.length : at
    }

    return raw
      .filter((page) => Array.isArray(page.frontmatter.os))
      .map((page) => {
        const os = page.frontmatter.os as string[]
        return {
          url: page.url,
          title: page.frontmatter.title ?? page.url,
          os,
          checked: checkedPerOs(page.frontmatter.lastChecked, os),
          locale: page.url.startsWith('/de/') ? 'de' : 'en'
        } satisfies PageStatusRow
      })
      // Setup order, then title for anything the setup page does not link.
      .sort((a, b) => rank(a.url) - rank(b.url) || a.title.localeCompare(b.title))
  }
})
