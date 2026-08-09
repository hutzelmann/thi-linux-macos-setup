<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const props = defineProps<{
  /** Card heading, the reader's word for the topic ("Printing", not "SMB"). */
  title: string
  /** Page that explains these values, e.g. "/en/wifi/". */
  link: string
}>()

const { lang } = useData()

/*
 * The "full page" href is a prop rather than a markdown link, so that a card's
 * identity does not depend on parsing heading levels out of the slot. The cost
 * is real and worth naming: VitePress checks dead links in markdown, and a prop
 * is not markdown, so these hrefs are not covered by `ignoreDeadLinks`.
 * Changing a page's path means changing them here by hand.
 */
const href = computed(() => withBase(props.link))

/*
 * The heading is the link, so something has to say where it goes. A cue on the
 * same line does that in the width a card has, which a sentence under the rows
 * did not.
 */
const label = computed(() =>
  lang.value.startsWith('de') ? 'Zur Anleitung' : 'Full documentation'
)
</script>

<template>
  <section class="fact-card">
    <a class="head" :href="href">
      <h3>{{ title }}</h3>
      <span class="cue">{{ label }} &rarr;</span>
    </a>

    <div class="body"><slot /></div>
  </section>
</template>

<style scoped>
.fact-card {
  display: flex;
  flex-direction: column;
  padding: 16px 18px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  background: var(--vp-c-bg-soft);
}

/*
 * Heading and cue on one row, baseline aligned, the whole row one link. The
 * heading carries the brand colour so it reads as clickable before the cue is
 * read at all.
 */
.head {
  display: flex;
  gap: 10px;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 10px;
  text-decoration: none;
}

.head h3 {
  margin: 0;
  border: 0;
  padding: 0;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--vp-c-brand-1);
}

.cue {
  flex: none;
  font-size: 11px;
  font-weight: 500;
  color: var(--vp-c-text-3);
  white-space: nowrap;
  transition: color 0.2s;
}

.head:hover h3 { text-decoration: underline; }
.head:hover .cue { color: var(--vp-c-brand-1); }

.body { flex: 1; }

/*
 * A markdown table needs a header row and the cards have nothing to put in one.
 * The alternative, letting this component group flat siblings into cards after
 * mount, needs DOM surgery that flashes on first paint.
 */
.fact-card :deep(thead) { display: none; }

.fact-card :deep(table) {
  display: table;
  width: 100%;
  margin: 0;
  border: 0;
  table-layout: fixed;
  font-size: 13px;
}

.fact-card :deep(tr) { background: transparent; border: 0; }

.fact-card :deep(td) {
  border: 0;
  border-top: 1px solid var(--vp-c-divider);
  padding: 7px 0;
  vertical-align: top;
  /* Hostnames are long and have no spaces the browser is willing to break. */
  overflow-wrap: anywhere;
}

.fact-card :deep(tr:first-child td) { border-top: 0; }

.fact-card :deep(td:first-child) {
  width: 40%;
  padding-right: 12px;
  color: var(--vp-c-text-2);
}

/* The footnote under the rows: what the card leaves out. */
.fact-card :deep(p) {
  margin: 12px 0 0;
  font-size: 12px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}

.fact-card :deep(code) { font-size: 12px; }
</style>
