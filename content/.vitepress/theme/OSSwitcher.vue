<script setup lang="ts">
import { ref, onMounted } from 'vue'

const OPTIONS = [
  { id: 'arch', label: 'Arch' },
  { id: 'debian', label: 'Debian' },
  { id: 'macos', label: 'macOS' }
] as const

const current = ref<string>('arch')

onMounted(() => {
  // The blocking head script already decided; read it rather than re-detecting,
  // so the control always agrees with what is on screen.
  current.value = document.documentElement.dataset.os ?? 'arch'
})

function choose(os: string) {
  current.value = os
  document.documentElement.dataset.os = os
  // An explicit choice is permanent. Detection never runs again — a Debian user
  // who corrected the Arch default should not be re-corrected on every visit.
  localStorage.setItem('os', os)
}
</script>

<template>
  <div class="os-switcher" role="group" aria-label="Operating system">
    <button
      v-for="o in OPTIONS"
      :key="o.id"
      type="button"
      :class="{ active: current === o.id }"
      :aria-pressed="current === o.id"
      @click="choose(o.id)"
    >
      {{ o.label }}
    </button>
  </div>
</template>

<style scoped>
.os-switcher {
  display: flex;
  gap: 2px;
  padding: 3px;
  border-radius: 8px;
  background: var(--vp-c-default-soft);
}

.os-switcher button {
  padding: 3px 10px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  line-height: 20px;
  color: var(--vp-c-text-2);
  transition: color 0.25s, background-color 0.25s;
}

.os-switcher button:hover {
  color: var(--vp-c-text-1);
}

.os-switcher button.active {
  color: var(--vp-c-text-1);
  background: var(--vp-c-bg);
}
</style>
