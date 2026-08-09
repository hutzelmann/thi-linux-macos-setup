---
title: Page status
description: Which pages a person has checked on a real machine, on which operating system, and what needs doing.
---

<script setup>
import { onMounted, ref } from 'vue'
import { useData, withBase } from 'vitepress'
import { data as pages } from './status.data.mts'
import { daysSince, exactDate, relativeDays } from '../../.vitepress/theme/relative-time'

const { lang, theme } = useData()

const OS_NAMES = { arch: 'Arch', debian: 'Debian', macos: 'macOS' }
const COLUMNS = ['arch', 'debian', 'macos']

const en = pages.filter(p => p.locale === 'en')

// Counted per page and operating system, because that is the unit a check
// covers. Three blocks on a page are three separate things to run.
const pairs = en.flatMap(p => p.os.map(os => p.checked[os]))
const counts = {
  checked: pairs.filter(Boolean).length,
  unchecked: pairs.filter(d => !d).length
}

// Counted in the browser, never at build time. See relative-time.ts.
const now = ref(null)
onMounted(() => { now.value = Date.now() })

// Same wording as the marker on each page, and the same phrasing as the
// last-edited line in the footer: one way of saying how long ago on the whole
// site. The exact day is the tooltip, so nothing is lost.
function label(date) {
  if (!date) return 'not checked yet'
  if (now.value === null) return date
  const days = daysSince(date, now.value)
  return days === null ? date : relativeDays(days, lang.value)
}

function exact(date) {
  return date ? exactDate(date, lang.value) : undefined
}

// Past the horizon in facts/project.yaml. Still a check, shown more quietly.
function stale(date) {
  if (!date || now.value === null) return false
  const days = daysSince(date, now.value)
  return days !== null && days > theme.value.staleAfterDays
}
</script>

# Page status

Generated from the pages themselves. Nothing here is hand-maintained, so it cannot be
out of date with the content.

<div class="status-summary">
  <span><strong>{{ counts.checked }}</strong> checked on a real machine</span>
  <span><strong>{{ counts.unchecked }}</strong> not checked yet</span>
</div>

Those numbers count a page and an operating system together, not pages. Every page here
gives Arch, Debian and macOS different steps, so following it on one of them is evidence
about that one and says nothing about the other two.

## What the two states mean

There is no third state and no field declaring which one a page is in. A page carries a
date for an operating system, or it does not.

**A date.** A person followed that operating system's steps on that date and reported
what happened. The date is the whole claim: it says when somebody looked, not that the
page is correct today.

**Not checked yet.** The steps are written up and their values come from the shared facts
file, so the hostnames and queue names match every other page. What they lack is somebody
confirming they work on real hardware.

Every page shows its state as a small dot next to the text, and it follows the operating
system selected in the navigation bar: switch from Arch to macOS and the marker changes
with the steps. Pages with nothing to run on a machine, the two about pages, carry a grey
dot and say so. They are not listed below.

Dates are shown as how long ago, the same way the last-edited line at the foot of every
page is. Hover any of them for the exact day. Past ${facts.project.stale_after_days} days
a check is shown more quietly, which is not a third state and not a claim the page went
wrong on that day. It says only that nobody has looked since, which is worth knowing
before you follow it.

## Every page

In the order of [a new machine on campus](/en/start/new-machine), which is the order
somebody actually works through them. Pages that page does not link come last.

<table class="status-table">
  <thead>
    <tr>
      <th>Page</th>
      <th v-for="os in COLUMNS" :key="os">{{ OS_NAMES[os] }}</th>
    </tr>
  </thead>
  <tbody>
    <tr v-for="p in en" :key="p.url">
      <td><a :href="withBase(p.url)">{{ p.title }}</a></td>
      <td v-for="os in COLUMNS" :key="os">
        <span v-if="!p.os.includes(os)" class="absent">not documented</span>
        <span
          v-else
          class="pill"
          :data-checked="p.checked[os] ? '' : null"
          :data-stale="stale(p.checked[os]) ? '' : null"
          :title="exact(p.checked[os])"
        >
          {{ label(p.checked[os]) }}
        </span>
      </td>
    </tr>
  </tbody>
</table>

## The most useful thing you can do

Take a page with no date for the system you run, follow it on your own machine, and
[file a check record](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml)
saying what happened, including "step 3 is wrong, it is actually X". The form asks which
operating system you used, and that answer is what decides where the date lands.

That is worth more than new pages. A page nobody has followed is a guess with good
formatting.

<style scoped>
.status-summary {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  margin: 24px 0;
  padding: 16px;
  border-radius: 8px;
  background: var(--vp-c-default-soft);
  font-size: 14px;
}

.status-table {
  display: table;
  width: 100%;
}

.pill {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  background: var(--vp-c-default-soft);
  font-size: 12px;
  white-space: nowrap;
}

.pill[data-checked] { background: var(--vp-c-success-soft); }
.pill[data-checked][data-stale] { background: var(--vp-c-warning-soft); }

/* An operating system the page has no block for is not an outstanding check. */
.absent {
  font-size: 12px;
  color: var(--vp-c-text-3);
}
</style>
