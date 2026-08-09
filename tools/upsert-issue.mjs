#!/usr/bin/env node
/**
 * Keep exactly one issue per recurring check, for the life of the project.
 *
 * A weekly job that opens an issue every time it fails produces fifty issues
 * about one dead URL, and the fiftieth is no more informative than the first.
 * One issue that keeps being updated has something the others do not: a
 * history, so you can see when it started and whether it ever recovered.
 *
 * Closed issues are searched too, and this is the part that matters. Looking
 * only at open ones means closing an issue whose cause has not gone away just
 * moves it: the next run finds nothing open and files a fresh one, so tidying
 * the tracker weekly produces a new issue weekly. Instead a close is taken at
 * face value. If the report has not changed since, nothing is said. If it has,
 * the same issue is reopened rather than replaced, so one recurring check owns
 * one issue number no matter how many years pass.
 *
 * The lookup is filtered by label and searched by title rather than paged
 * through the whole tracker. An unfiltered page of 100 is fine until the
 * project has 100 open issues, at which point the lookup starts missing and
 * duplicating, which is exactly when a duplicate hurts most.
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

/*
 * The issue this check owns, open or closed, or null if it has never filed one.
 *
 * --search narrows server-side so the result does not depend on how busy the
 * tracker is; the exact-title comparison still decides, because search is
 * fuzzy and would otherwise match a contributor's issue that happens to share
 * a word. Newest first, so a title that was somehow filed twice resolves to
 * the one still in use.
 */
function findExisting(title, label) {
  const args = [
    'issue',
    'list',
    '--state',
    'all',
    '--limit',
    '100',
    '--json',
    'number,title,body,state',
    '--search',
    `"${title}" in:title sort:created-desc`
  ]
  if (label) args.push('--label', label)
  const match = JSON.parse(gh(args)).find((issue) => issue.title === title)
  return match ?? null
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
  const existing = findExisting(args.title, args.label ? String(args.label) : null)
  const isOpen = existing?.state === 'OPEN'

  // Nothing to report: say nothing. A check that posts "still fine" every week
  // trains people to stop reading it.
  if (args['close-if-ok'] && !body) {
    if (isOpen) {
      gh(['issue', 'comment', String(existing.number), '--body', 'This no longer reproduces. Closing.'])
      gh(['issue', 'close', String(existing.number)])
      console.log(`closed #${existing.number}`)
    } else {
      console.log('nothing to report')
    }
    return 0
  }

  if (isOpen) {
    gh(['issue', 'edit', String(existing.number), '--body', body])
    console.log(`updated #${existing.number}`)
    return 0
  }

  /*
   * Closed, and the report says the same thing it said when it was closed.
   * Somebody read this and decided it did not need to stay open, and nothing
   * has happened since to change that. Reopening would be the tracker arguing
   * with the person maintaining it.
   */
  if (existing && sameReport(existing.body, body)) {
    console.log(`unchanged since #${existing.number} was closed; saying nothing`)
    return 0
  }

  if (existing) {
    gh(['issue', 'reopen', String(existing.number)])
    gh(['issue', 'edit', String(existing.number), '--body', body])
    gh([
      'issue',
      'comment',
      String(existing.number),
      '--body',
      'Reopened because what this check observes has changed since it was closed. The body above is the current observation.'
    ])
    console.log(`reopened #${existing.number}`)
    return 0
  }

  const create = ['issue', 'create', '--title', args.title, '--body', body]
  if (args.label) create.push('--label', String(args.label))
  console.log(gh(create).trim())
  return 0
}

/*
 * Whether two reports say the same thing. Compared after normalising blank
 * lines and trailing spaces, since the body is assembled by a shell heredoc
 * and an incidental whitespace change is not news.
 */
export function sameReport(a, b) {
  const norm = (t) => String(t ?? '').replace(/\r\n/g, '\n').replace(/[ \t]+$/gm, '').trim()
  return norm(a) === norm(b)
}

if (process.argv[1] && process.argv[1].endsWith('upsert-issue.mjs')) {
  process.exit(main(process.argv.slice(2)))
}
