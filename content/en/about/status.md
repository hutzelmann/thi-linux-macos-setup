---
title: Page status
description: Which pages have been checked on a real machine, which are still raw notes, and what needs doing.
---

<script setup>
import { data as pages } from './status.data.mts'

const en = pages.filter(p => p.locale === 'en')
const counts = {
  imported: en.filter(p => p.status === 'imported').length,
  structured: en.filter(p => p.status === 'structured').length,
  checked: en.filter(p => p.status === 'checked').length
}
</script>

# Page status

Generated from the pages themselves. Nothing here is hand-maintained, so it cannot be
out of date with the content.

<div class="status-summary">
  <span><strong>{{ counts.checked }}</strong> checked on a real machine</span>
  <span><strong>{{ counts.structured }}</strong> written up, not yet checked</span>
  <span><strong>{{ counts.imported }}</strong> raw notes</span>
</div>

## What the states mean

**Imported.** Notes carried over as they were. Probably correct, definitely not
polished, and nobody has followed them start to finish. These are the easiest pages to
improve: read one, try it, and fix whatever was wrong.

**Written up.** Follows the page structure, values come from the shared facts file. What
it lacks is somebody confirming it works on real hardware.

**Checked.** A person ran the steps on the stated date and reported the result.

## Every page

<table class="status-table">
  <thead>
    <tr><th>Page</th><th>State</th><th>Last checked</th></tr>
  </thead>
  <tbody>
    <tr v-for="p in en" :key="p.url">
      <td><a :href="p.url">{{ p.title }}</a></td>
      <td>
        <span class="pill" :data-status="p.status">
          {{ p.status === 'imported' ? 'raw notes' : p.status === 'structured' ? 'written up' : 'checked' }}
        </span>
      </td>
      <td>{{ p.lastChecked ?? 'not checked' }}</td>
    </tr>
  </tbody>
</table>

## The most useful thing you can do

Take a page marked *raw notes* or *written up*, follow it on your own machine, and
[file a check record](https://github.com/hutzelmann/thi-linux-macos-setup/issues/new?template=check-record.yml)
saying what happened, including "step 3 is wrong, it is actually X".

That is worth more than new pages. A page nobody has verified is a guess with good
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
  font-size: 12px;
  white-space: nowrap;
  background: var(--vp-c-default-soft);
}

.pill[data-status='imported'] { background: var(--vp-c-warning-soft); }
.pill[data-status='checked'] { background: var(--vp-c-success-soft); }
</style>
