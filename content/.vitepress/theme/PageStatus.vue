<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useData, withBase } from 'vitepress'
import { daysSince, exactDate, relativeDays } from './relative-time'

const props = defineProps<{
  /**
   * Where this instance is mounted. Both are always rendered and the
   * breakpoint below decides which one is visible, because VitePress only
   * shows the aside column from 1280px up.
   */
  variant: 'aside' | 'inline'
}>()

const { frontmatter, lang, theme } = useData()

const de = computed(() => lang.value.startsWith('de'))

/*
 * The marker follows the operating system selected in the navigation bar,
 * because the steps do. A page current on Arch and untouched on macOS is two
 * different claims, and showing one averaged verdict would make the weaker of
 * them look like the stronger.
 *
 * The blocking head script sets html[data-os] before first paint; this reads
 * that rather than re-detecting, and watches it so switching the control moves
 * the marker with the steps. Server rendering has no document, so it renders
 * the same default the head script falls back to.
 */
const OS_NAMES: Record<string, string> = { arch: 'Arch', debian: 'Debian', macos: 'macOS' }
const currentOs = ref('arch')
let observer: MutationObserver | null = null

/*
 * How long ago reads better than a date, but only in the browser. Rendered on
 * the server it would bake "yesterday" into a page that is served for weeks,
 * and the client would then correct it, which is a hydration mismatch and a
 * visible flicker. The server writes the day; the browser relativises it.
 */
const mounted = ref(false)

onMounted(() => {
  mounted.value = true
  const root = document.documentElement
  const read = () => { currentOs.value = root.dataset.os ?? 'arch' }
  read()
  observer = new MutationObserver(read)
  observer.observe(root, { attributes: true, attributeFilter: ['data-os'] })
})

onUnmounted(() => observer?.disconnect())

/*
 * There is no `status:` field. A page is checked, for one system, exactly when
 * it carries a date for that system, so the two can never contradict each
 * other and "checked" cannot be claimed without saying when.
 *
 * The gate is `os`: a page declares which operating systems it has blocks for,
 * and a page with no steps to run on a machine has nothing to check. That
 * keeps the marker off the about pages without a second opt-out field.
 */
const checkable = computed(() => Array.isArray(frontmatter.value.os))

/*
 * An unquoted YAML date is parsed into a Date, which arrives here as a Date
 * during the server render and as an ISO string in the browser bundle. Printed
 * raw, that is `2026-05-02T00:00:00.000Z`. Only the day was ever meant.
 */
function day(value: unknown): string | null {
  if (!value) return null
  if (value instanceof Date) return value.toISOString().slice(0, 10)
  return String(value).slice(0, 10)
}

/** The date recorded for the system being read, never a single date for the page. */
const lastChecked = computed(() => {
  const recorded = frontmatter.value.lastChecked
  if (!recorded || typeof recorded !== 'object' || Array.isArray(recorded)) return null
  return day((recorded as Record<string, unknown>)[currentOs.value])
})

/*
 * Past the threshold in facts/project.yaml the dot goes amber. Not a third
 * state and not a claim the page went wrong on that day: the check still
 * stands, and this says only that nobody has looked since, which is what you
 * need in order to judge it.
 */
const stale = computed(() => {
  if (!lastChecked.value) return false
  const days = daysSince(lastChecked.value)
  const threshold = theme.value.staleAfterDays
  return days !== null && typeof threshold === 'number' && days > threshold
})

const state = computed(() => {
  if (!checkable.value) return 'none'
  return lastChecked.value ? 'checked' : 'open'
})

const osName = computed(() => OS_NAMES[currentOs.value] ?? currentOs.value)

const label = computed(() => {
  if (state.value === 'none') {
    return de.value ? 'nichts zu prüfen' : 'nothing to check here'
  }
  if (state.value === 'checked') {
    const days = mounted.value ? daysSince(lastChecked.value as string) : null
    if (days !== null) {
      const ago = relativeDays(days, lang.value)
      return de.value
        ? `${osName.value}-Schritte ${ago} geprüft`
        : `${osName.value} steps checked ${ago}`
    }
    return de.value
      ? `${osName.value}-Schritte am ${lastChecked.value} geprüft`
      : `${osName.value} steps checked ${lastChecked.value}`
  }
  return de.value
    ? `${osName.value}-Schritte noch nicht geprüft`
    : `${osName.value} steps not checked yet`
})

/** The exact day, on hover, since the label carries the short form. */
const title = computed(() =>
  lastChecked.value ? exactDate(lastChecked.value, lang.value) : undefined
)

// The page explaining what the states mean, in the language being read. Both
// exist, so this never leaves the reader's locale.
const href = computed(() => withBase(de.value ? '/de/about/status' : '/en/about/status'))
</script>

<template>
  <!--
    A dot and a date, never a seal. The filled dot means a date exists; it does
    not say the page is good. What the project can honestly report is whether
    somebody looked, and when. Pages with no steps to run say so rather than
    dropping the line, so nothing shifts as the reader moves between pages.
  -->
  <p class="page-status" :data-variant="variant" :data-state="state" :data-stale="stale || undefined">
    <span class="dot" aria-hidden="true" />
    <a class="label" :href="href" :title="title">{{ label }}</a>
  </p>
</template>

<style scoped>
.page-status {
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: 12.5px;
  line-height: 1.5;
  color: var(--vp-c-text-3);
}

.dot {
  flex: none;
  width: 8px;
  height: 8px;
  border: 1px solid var(--vp-c-text-3);
  border-radius: 50%;
}

.page-status[data-state='checked'] .dot {
  border-color: var(--vp-c-success-2);
  background: var(--vp-c-success-2);
}

/*
 * Filled grey, not hollow: hollow means a check is outstanding, and on a page
 * with no steps none ever will be. Rendering the line on every page also keeps
 * the heading in the same place as the reader moves between pages.
 */
.page-status[data-state='checked'][data-stale] .dot {
  border-color: var(--vp-c-warning-2);
  background: var(--vp-c-warning-2);
}

.page-status[data-state='none'] .dot {
  border-color: var(--vp-c-divider);
  background: var(--vp-c-divider);
}

.label {
  color: inherit;
  text-decoration: none;
}

.label:hover {
  color: var(--vp-c-text-2);
  text-decoration: underline;
}

.page-status[data-variant='inline'] {
  margin: 0 0 20px;
}

.page-status[data-variant='aside'] {
  margin: 0 0 16px;
}

/*
 * The swap is CSS, not matchMedia: a JavaScript breakpoint renders one variant
 * during the static build and possibly the other on hydration, which is a
 * mismatch plus a visible flash. `display: none` also keeps the hidden copy out
 * of the accessibility tree, so a screen reader hears the status once.
 *
 * 1280px is VitePress's own threshold for showing the aside column.
 */
.page-status[data-variant='aside'] {
  display: none;
}

@media (min-width: 1280px) {
  .page-status[data-variant='aside'] {
    display: flex;
  }

  .page-status[data-variant='inline'] {
    display: none;
  }
}

/* The aside is not printed, so paper falls back to the inline copy. */
@media print {
  .page-status[data-variant='aside'] {
    display: none;
  }

  .page-status[data-variant='inline'] {
    display: flex;
  }
}
</style>
