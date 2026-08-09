#!/usr/bin/env node
/**
 * Keep exactly one issue per recurring check.
 *
 * A weekly job that opens an issue every time it fails produces fifty issues
 * about one dead URL, and the fiftieth is no more informative than the first.
 * One issue that keeps being updated has something the others do not: a
 * history, so you can see when it started and whether it ever recovered.
 *
 * Usage: node tools/upsert-issue.mjs --title="..." --label=drift [--close-if-ok]
 *        body on stdin
 *
 * Needs the gh CLI and a token, so it only runs inside the workflow.
 */
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

function gh(args, input) {
  return execFileSync('gh', args, { encoding: 'utf8', input })
}

function findOpen(title) {
  const raw = gh([
    'issue',
    'list',
    '--state',
    'open',
    '--limit',
    '100',
    '--json',
    'number,title'
  ])
  const match = JSON.parse(raw).find((issue) => issue.title === title)
  return match ? match.number : null
}

function main(argv) {
  const args = Object.fromEntries(
    argv.filter((a) => a.startsWith('--')).map((a) => {
      const [k, ...v] = a.replace(/^--/, '').split('=')
      return [k, v.length ? v.join('=') : true]
    })
  )
  if (!args.title) {
    console.error('Usage: node tools/upsert-issue.mjs --title="..." [--label=drift] [--close-if-ok]')
    return 2
  }

  const body = readFileSync(0, 'utf8').trim()
  const existing = findOpen(args.title)

  // Nothing to report and nothing open: say nothing. A check that posts "still
  // fine" every week trains people to stop reading it.
  if (args['close-if-ok'] && !body) {
    if (existing) {
      gh(['issue', 'comment', String(existing), '--body', 'This no longer reproduces. Closing.'])
      gh(['issue', 'close', String(existing)])
      console.log(`closed #${existing}`)
    } else {
      console.log('nothing to report')
    }
    return 0
  }

  if (existing) {
    gh(['issue', 'edit', String(existing), '--body', body])
    console.log(`updated #${existing}`)
    return 0
  }

  const create = ['issue', 'create', '--title', args.title, '--body', body]
  if (args.label) create.push('--label', String(args.label))
  console.log(gh(create).trim())
  return 0
}

if (process.argv[1] && process.argv[1].endsWith('upsert-issue.mjs')) {
  process.exit(main(process.argv.slice(2)))
}
