#!/usr/bin/env node
/**
 * Scaffold a page with correct frontmatter, the standard section order, and a
 * sidebar entry.
 *
 * A blank file is intimidating and the frontmatter has non-obvious required
 * fields, so the first contribution usually stalls before it starts. This makes
 * the correct shape the default and the wrong shape hard to produce.
 *
 * Usage: npm run new-page
 */
import { createInterface } from 'node:readline/promises'
import { stdin, stdout } from 'node:process'
import { mkdir, readFile, writeFile, access } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = fileURLToPath(new URL('..', import.meta.url))
const SECTIONS = [
  'printing', 'wifi', 'vpn', 'network', 'shares', 'files', 'devices', 'vm', 'policy'
]

const rl = createInterface({ input: stdin, output: stdout })

async function ask(question, fallback) {
  const answer = (await rl.question(fallback ? `${question} [${fallback}] ` : `${question} `)).trim()
  return answer || fallback || ''
}

async function exists(path) {
  try {
    await access(path)
    return true
  } catch {
    return false
  }
}

function template({ title, section, osList }) {
  const osBlocks = osList
    .map(
      (os) => `::: os ${os}

\`\`\`bash
# ${os} steps here
\`\`\`

:::`
    )
    .join('\n\n')

  return `---
title: ${title}
description: One sentence, in the words someone would search for.
status: imported
os: [${osList.join(', ')}]
---

# ${title}

What this page gets you, in one sentence.

Official documentation: [link](https://www.thi.de/service/it-service/). Account and
hardware problems belong there, not here.

## Documented values

Values come from \`facts/${section}.yaml\` and are written as
\`\${facts.${section}.some_key}\`. Never type a hostname or queue name directly; the
build fails if you do, because the next rename would miss it.

## Steps

Plain language first. Assume the reader has never opened a terminal.

${osBlocks}

## Verify

How to tell it worked.

## Known quirks

What went wrong for you, and what fixed it. This section is usually the most valuable
part of the page.

---

::: info Imported notes
Replace this with real content, then change \`status\` to \`structured\`. Once someone has
followed the steps on a real machine, set \`status: checked\` and add
\`lastChecked: YYYY-MM-DD\`.
:::
`
}

async function main() {
  console.log('\nNew page\n')

  const title = await ask('Page title (as a reader would search for it):')
  if (!title) {
    console.error('A title is required.')
    process.exit(1)
  }

  const section = await ask(`Section (${SECTIONS.join(', ')}):`, 'printing')
  const slug = await ask(
    'File name:',
    title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
  )
  const osAnswer = await ask('Which systems? (arch debian macos):', 'arch debian macos')
  const osList = osAnswer.split(/[\s,]+/).filter(Boolean)

  const relative = join('en', section, `${slug}.md`)
  const target = join(ROOT, 'content', relative)

  if (await exists(target)) {
    console.error(`\n${relative} already exists.`)
    process.exit(1)
  }

  await mkdir(dirname(target), { recursive: true })
  await writeFile(target, template({ title, section, osList }))

  // Add the sidebar entry so contributors never have to touch config.
  const sidebarPath = join(ROOT, 'content/.vitepress/sidebar.mts')
  const sidebar = await readFile(sidebarPath, 'utf8')
  const entry = `      { text: '${title.replace(/'/g, "\\'")}', link: '/en/${section}/${slug}' },`
  const marker = new RegExp(`(link: '/en/${section}/[^']*' \\},?\\n)`)

  if (marker.test(sidebar)) {
    await writeFile(sidebarPath, sidebar.replace(marker, `$1${entry}\n`))
    console.log('  sidebar entry added')
  } else {
    console.log(`  add this to content/.vitepress/sidebar.mts:\n${entry}`)
  }

  console.log(`\nCreated content/${relative}`)
  console.log('\nNext:')
  console.log('  npm run dev     preview at http://localhost:5173')
  console.log('  npm run check   before committing\n')
}

main()
  .catch((error) => {
    console.error(error.message)
    process.exit(1)
  })
  .finally(() => rl.close())
