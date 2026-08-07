<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const { frontmatter, lang } = useData()

const de = computed(() => lang.value.startsWith('de'))

const TEXT = {
  imported: {
    en: 'Imported notes. Not yet restructured, and nobody has checked them against a real machine.',
    de: 'Übernommene Notizen. Noch nicht überarbeitet und bisher an keinem Gerät überprüft.'
  },
  structured: {
    en: 'Written up, values taken from the shared facts file. Not checked on a machine yet.',
    de: 'Ausgearbeitet, Werte stammen aus der gemeinsamen Faktendatei. Noch nicht an einem Gerät überprüft.'
  },
  checked: {
    en: 'Last checked on',
    de: 'Zuletzt geprüft am'
  }
} as const

const status = computed(() => frontmatter.value.status as keyof typeof TEXT | undefined)
const lastChecked = computed(() => frontmatter.value.lastChecked as string | undefined)

const label = computed(() => {
  if (!status.value) return null
  const l = de.value ? 'de' : 'en'
  if (status.value === 'checked') {
    return lastChecked.value
      ? `${TEXT.checked[l]} ${lastChecked.value}`
      : TEXT.structured[l]
  }
  return TEXT[status.value]?.[l] ?? null
})
</script>

<template>
  <!--
    Deliberately a sentence with a date, never a ✅ seal. The project makes no
    accuracy claim; what it can honestly report is when a human last looked.
  -->
  <div v-if="label" class="page-status" :data-status="status">
    {{ label }}
  </div>
</template>

<style scoped>
.page-status {
  margin: 0 0 24px;
  padding: 8px 14px;
  border-left: 3px solid var(--vp-c-default-2);
  border-radius: 0 4px 4px 0;
  background: var(--vp-c-default-soft);
  font-size: 13px;
  line-height: 1.5;
  color: var(--vp-c-text-2);
}

.page-status[data-status='imported'] {
  border-left-color: var(--vp-c-warning-2);
}

.page-status[data-status='checked'] {
  border-left-color: var(--vp-c-success-2);
}
</style>
