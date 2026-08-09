<script setup lang="ts">
import { computed } from 'vue'
import { useData, useRoute } from 'vitepress'

const { lang, theme, frontmatter, page, site } = useData()
const route = useRoute()

const de = computed(() => lang.value.startsWith('de'))

/*
 * The repository slug comes from the theme config, which reads facts/project.yaml.
 * Writing it here would be a second copy of a value the whole project keeps once.
 */
const repo = computed(() => theme.value.repo)

/** Editing goes through the pattern the theme already configures, wording included. */
const editHref = computed(
  () => `https://github.com/${repo.value}/edit/main/content/${page.value.filePath}`
)

/*
 * The page as the site knows it, with the deployment base stripped. The forms and
 * tools/check-record.mjs match on `/en/wifi/`, which is what the sidebar and the
 * status board use; `/thi-linux-macos-setup/en/wifi/` matches nothing.
 */
const pagePath = computed(() => {
  const base = site.value.base
  return base !== '/' && route.path.startsWith(base) ? route.path.slice(base.length - 1) : route.path
})

function issueHref(template: string, labels: string, extra: Record<string, string> = {}) {
  const params = new URLSearchParams({ template, page: pagePath.value, labels, ...extra })
  return `https://github.com/${repo.value}/issues/new?${params}`
}

/**
 * Deep-links into the issue form with the page already filled in. A report that
 * arrives with its page path attached is actionable; "the printer page is wrong"
 * is not.
 */
const reportHref = computed(() => issueHref('something-wrong.yml', 'page-feedback'))

/*
 * The check record carries today's date as well, because the one thing the form
 * cannot infer is when you ran the steps, and the common answer is "just now".
 */
const checkHref = computed(() =>
  issueHref('check-record.yml', 'check-record', { date: new Date().toISOString().slice(0, 10) })
)

/*
 * Which systems this page actually has steps for, named the way the reader
 * selects them. A date only ever means one of these, so saying which three the
 * page covers is what makes the marker above legible.
 */
const OS_LABELS: Record<string, string> = {
  arch: 'Arch Linux',
  debian: 'Debian / Ubuntu',
  macos: 'macOS'
}

const coverage = computed(() => {
  const os = frontmatter.value.os
  if (!Array.isArray(os) || os.length === 0) return null
  const names = os.map((id: string) => OS_LABELS[id] ?? id).join(', ')
  return de.value ? `Schritte auf dieser Seite: ${names}` : `Steps on this page: ${names}`
})
</script>

<template>
  <div class="page-actions">
    <div class="links">
      <a class="action" :href="editHref" target="_blank" rel="noreferrer">
        <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><path fill="currentColor" d="M11.013 1.427a1.75 1.75 0 0 1 2.474 0l1.086 1.086a1.75 1.75 0 0 1 0 2.474l-8.61 8.61c-.21.21-.47.364-.756.445l-3.251.93a.75.75 0 0 1-.927-.928l.929-3.25c.081-.286.235-.547.445-.758l8.61-8.61Zm1.414 1.06a.25.25 0 0 0-.354 0L10.811 3.75l1.439 1.44 1.263-1.263a.25.25 0 0 0 0-.354l-1.086-1.086ZM11.189 6.25 9.75 4.81l-6.286 6.287a.25.25 0 0 0-.064.108l-.558 1.953 1.953-.558a.25.25 0 0 0 .108-.064l6.286-6.286Z"></path></svg>
        {{ de ? 'Diese Seite auf GitHub bearbeiten' : 'Edit this page on GitHub' }}
      </a>
      <a class="action" :href="reportHref" target="_blank" rel="noreferrer">
        <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><path fill="currentColor" d="M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0 1 14.082 15H1.918a1.75 1.75 0 0 1-1.543-2.575ZM8 5a.75.75 0 0 0-.75.75v2.5a.75.75 0 0 0 1.5 0v-2.5A.75.75 0 0 0 8 5Zm1 6a1 1 0 1 0-2 0 1 1 0 0 0 2 0Z"></path></svg>
        {{ de ? 'Stimmt hier etwas nicht?' : 'Something wrong here?' }}
      </a>
      <!--
        Only where there are steps to run. Offering "this worked for me" on a page
        with nothing to follow invites a date that would claim a check nobody made.
      -->
      <a v-if="coverage" class="action" :href="checkHref" target="_blank" rel="noreferrer">
        <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><path fill="currentColor" d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0Zm0 1.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13Zm3.28 4.22a.75.75 0 0 1 0 1.06l-3.97 3.97a.75.75 0 0 1-1.06 0L4.72 9.22a.75.75 0 1 1 1.06-1.06l1 1 3.44-3.44a.75.75 0 0 1 1.06 0Z"></path></svg>
        {{ de ? 'Hat bei mir funktioniert' : 'This worked for me' }}
      </a>
    </div>
    <p v-if="coverage" class="coverage">{{ coverage }}</p>
  </div>
</template>

<style scoped>
/*
 * One centred column: three pill-shaped actions, then the two lines of context
 * under them. The default theme puts the edit link and the date in a row of
 * their own below the pager, where they read as leftovers; doc-footer.css hides
 * that copy and this is the replacement.
 */
.page-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: center;
  padding-bottom: 20px;
}

.links {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
}

/* Buttons rather than links: three of them in a row read as a set of things to
   do, where three underlined phrases read as a sentence that broke. */
.action {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  padding: 5px 12px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 20px;
  background: var(--vp-c-bg);
  font-size: 13px;
  font-weight: 500;
  line-height: 20px;
  color: var(--vp-c-text-2);
  text-decoration: none;
  white-space: nowrap;
  transition: border-color 0.25s, background-color 0.25s, color 0.25s;
}

.action:hover {
  border-color: var(--vp-c-brand-1);
  background: var(--vp-c-bg-soft);
  color: var(--vp-c-brand-1);
}

.action svg {
  flex: none;
  opacity: 0.7;
}

.action:hover svg {
  opacity: 1;
}

.edited,
.coverage {
  margin: 0;
  font-size: 13px;
  line-height: 20px;
  color: var(--vp-c-text-3);
}

.edited a {
  color: inherit;
  text-decoration: none;
}

.edited a:hover {
  color: var(--vp-c-text-2);
  text-decoration: underline;
}

/* On paper the actions are three dead links and a date nobody can click. */
@media print {
  .page-actions {
    display: none;
  }
}
</style>
