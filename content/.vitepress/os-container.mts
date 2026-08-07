import container from 'markdown-it-container'
import type MarkdownIt from 'markdown-it'

export const SUPPORTED_OS = ['arch', 'debian', 'macos'] as const
export type OS = (typeof SUPPORTED_OS)[number]

export const OS_LABEL: Record<OS, string> = {
  arch: 'Arch Linux',
  debian: 'Debian / Ubuntu',
  macos: 'macOS'
}

/**
 * `::: os arch` … `:::` becomes a block tagged with the OS it belongs to.
 *
 * Visibility is pure CSS keyed off `html[data-os]`, which the blocking head
 * script sets before first paint. Every OS variant stays in the DOM, so search
 * indexes all of them and a reader who lands via a link to another OS still
 * finds the content by switching the selector. No hydration, no flash.
 */
export function osContainer(md: MarkdownIt): void {
  md.use(container, 'os', {
    validate: (params: string) => /^os\s+\S+/.test(params.trim()),
    render(tokens: any[], idx: number) {
      const token = tokens[idx]
      if (token.nesting !== 1) return '</div>\n'

      const arg = token.info.trim().slice(2).trim().toLowerCase()
      if (!SUPPORTED_OS.includes(arg as OS)) {
        throw new Error(
          `Unknown OS "${arg}" in ::: os. Supported: ${SUPPORTED_OS.join(', ')}.`
        )
      }
      const label = OS_LABEL[arg as OS]
      return `<div class="os-block" data-os-block="${arg}" aria-label="${label}">\n`
    }
  })
}
