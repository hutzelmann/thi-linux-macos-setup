<script setup lang="ts">
import { computed } from 'vue'
import { useData, useRoute } from 'vitepress'

const REPO = 'hutzelmann/thi-linux-macos-setup'

const { lang } = useData()
const route = useRoute()

const de = computed(() => lang.value.startsWith('de'))

/**
 * Deep-links into the issue form with the page already filled in. A report that
 * arrives with its page path attached is actionable; "the printer page is wrong"
 * is not.
 */
const href = computed(() => {
  const params = new URLSearchParams({
    template: 'something-wrong.yml',
    labels: 'page-feedback',
    page: route.path
  })
  return `https://github.com/${REPO}/issues/new?${params}`
})
</script>

<template>
  <a class="report-button" :href="href" target="_blank" rel="noreferrer">
    {{ de ? 'Stimmt hier etwas nicht?' : 'Something wrong here?' }}
  </a>
</template>

<style scoped>
.report-button {
  display: inline-block;
  margin-top: 8px;
  font-size: 14px;
  font-weight: 500;
  color: var(--vp-c-brand-1);
  text-decoration: none;
}

.report-button:hover {
  text-decoration: underline;
}
</style>
