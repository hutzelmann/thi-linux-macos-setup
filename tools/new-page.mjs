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
import { execFileSync } from 'node:child_process'

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
Replace this with real content. Once somebody has followed the steps on a real machine,
record it with \`npm run record -- /en/\${section}/\`, which writes the date under the
operating system it was run on. \`lastChecked\` is a map, never one date: this page gives
each system different steps, so a run on one says nothing about the others. Record
nobody else's run but your own.
:::
`
}


/*
 * The German stub. A stub beats a missing file: the reader still lands somewhere,
 * the language switcher still works, and check-translations.sh passes because the
 * pair exists and records the hash it was made from.
 */
function templateDe({ titleDe, section, slug, osList, sourceHash }) {
  const blocks = osList
    .map((os) => `::: os ${os}\n\`\`\`bash\n# ${os} steps here\n\`\`\`\n:::`)
    .join('\n\n')

  return `---
title: ${titleDe}
description: Ein Satz, in den Worten, nach denen jemand suchen würde.
os: [${osList.join(', ')}]
translatedFrom: ${sourceHash}
---

# ${titleDe}

${blocks}

::: info Übersetzung
Diese Seite ist eine Übersetzung von \`/en/${section}/${slug}\`. Der \`translatedFrom\`-Hash
oben zeigt auf den Stand, aus dem übersetzt wurde. Ist ein Mensch den Schritten auf einem
echten Rechner gefolgt, hält \`npm run record\` das fest, und zwar unter dem
Betriebssystem, auf dem der Lauf stattfand. \`lastChecked\` ist eine Zuordnung, kein
einzelnes Datum.
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

  const titleDe = await ask('German title:', title)
  const section = await ask(`Section (${SECTIONS.join(', ')}):`, 'printing')
  const slug = await ask(
    'File name:',
    title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
  )
  const osAnswer = await ask('Which systems? (arch debian macos):', 'arch debian macos')
  const osList = osAnswer.split(/[\s,]+/).filter(Boolean)

  const relative = join('en', section, `${slug}.md`)
  const relativeDe = join('de', section, `${slug}.md`)
  const target = join(ROOT, 'content', relative)
  const targetDe = join(ROOT, 'content', relativeDe)

  for (const [path, file] of [[relative, target], [relativeDe, targetDe]]) {
    if (await exists(file)) {
      console.error(`\n${path} already exists.`)
      process.exit(1)
    }
  }

  await mkdir(dirname(target), { recursive: true })
  await writeFile(target, template({ title, section, osList }))

  /*
   * The hash of the English file as just written, which is what
   * check-translations.sh compares against. Writing the German stub without it
   * would create the pair and fail the check in the same step.
   */
  const sourceHash = execFileSync('git', ['hash-object', target], { encoding: 'utf8' }).trim()

  await mkdir(dirname(targetDe), { recursive: true })
  await writeFile(targetDe, templateDe({ titleDe, section, slug, osList, sourceHash }))

  // Add both sidebar entries so contributors never have to touch config.
  const sidebarPath = join(ROOT, 'content/.vitepress/sidebar.mts')
  let sidebar = await readFile(sidebarPath, 'utf8')
  const manual = []

  for (const [locale, text] of [['en', title], ['de', titleDe]]) {
    const entry = `      { text: '${text.replace(/'/g, "\\'")}', link: '/${locale}/${section}/${slug}' },`
    const marker = new RegExp(`(link: '/${locale}/${section}/[^']*' \\},?\\n)`)

    if (marker.test(sidebar)) {
      sidebar = sidebar.replace(marker, `$1${entry}\n`)
      console.log(`  ${locale} sidebar entry added`)
    } else {
      manual.push(entry)
    }
  }

  await writeFile(sidebarPath, sidebar)
  if (manual.length) {
    console.log(`  add this to content/.vitepress/sidebar.mts:\n${manual.join('\n')}`)
  }

  console.log(`\nCreated content/${relative}`)
  console.log(`Created content/${relativeDe}`)
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
