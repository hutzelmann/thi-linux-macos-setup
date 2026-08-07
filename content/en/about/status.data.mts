import { createContentLoader } from 'vitepress'

export interface PageStatusRow {
  url: string
  title: string
  status: 'imported' | 'structured' | 'checked'
  lastChecked: string | null
  locale: 'en' | 'de'
}

const ORDER: Record<string, number> = { imported: 0, structured: 1, checked: 2 }

/**
 * The needs-love board is generated, never hand-written: a hand-maintained list
 * of what needs work is itself a thing that needs work, and it goes stale first.
 * Pages declare their own state in frontmatter; this collects it.
 */
export default createContentLoader('*/**/*.md', {
  includeSrc: false,
  transform(raw): PageStatusRow[] {
    return raw
      .filter((page) => page.frontmatter.status)
      .map((page) => ({
        url: page.url,
        title: page.frontmatter.title ?? page.url,
        status: page.frontmatter.status,
        lastChecked: page.frontmatter.lastChecked ?? null,
        locale: page.url.startsWith('/de/') ? 'de' : 'en'
      }))
      .sort((a, b) => ORDER[a.status] - ORDER[b.status] || a.title.localeCompare(b.title))
  }
})
