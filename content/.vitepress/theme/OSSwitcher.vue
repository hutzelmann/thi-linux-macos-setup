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

function onSelect(event: Event) {
  choose((event.target as HTMLSelectElement).value)
}

function choose(os: string) {
  current.value = os
  document.documentElement.dataset.os = os
  // An explicit choice is permanent. Detection never runs again, and a Debian user
  // who corrected the Arch default should not be re-corrected on every visit.
  localStorage.setItem('os', os)
}
</script>

<!--
  Two forms of the same control, swapped by width. The three buttons need about
  1360px of navbar before the GitHub link starts being cut off; below that the
  bar overflows and takes the appearance toggle and the language menu off the
  right edge with it, which on a phone leaves them unreachable.

  The narrow form is still a control showing the current operating system, not a
  menu that hides it. That distinction is the whole point: a browser cannot tell
  Debian from Arch, so a Debian reader is looking at the Arch default and has to
  be able to see that at a glance in order to correct it.
-->
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

  <div class="os-select">
    <select
      :value="current"
      aria-label="Operating system"
      @change="onSelect"
    >
      <option v-for="o in OPTIONS" :key="o.id" :value="o.id">{{ o.label }}</option>
    </select>
  </div>
</template>

<style scoped>
/*
 * The swap is CSS rather than a matchMedia check, so the static render and the
 * hydrated page agree. `display: none` also keeps the hidden form out of the
 * accessibility tree, so the control is announced once.
 */
.os-switcher {
  display: none;
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

.os-select {
  position: relative;
  display: flex;
  align-items: center;
}

.os-select select {
  padding: 4px 26px 4px 10px;
  border-radius: 8px;
  background: var(--vp-c-default-soft);
  font-size: 13px;
  font-weight: 500;
  line-height: 20px;
  color: var(--vp-c-text-1);
  /* Native chevrons differ per platform and are wider than the one below. */
  appearance: none;
}

/* Inherits the page theme, so the open option list is not white on dark. */
.os-select select option {
  background: var(--vp-c-bg-elv);
  color: var(--vp-c-text-1);
}

.os-select::after {
  position: absolute;
  right: 10px;
  width: 6px;
  height: 6px;
  border-right: 1.5px solid var(--vp-c-text-3);
  border-bottom: 1.5px solid var(--vp-c-text-3);
  content: '';
  pointer-events: none;
  transform: translateY(-2px) rotate(45deg);
}

@media (min-width: 1360px) {
  .os-switcher {
    display: flex;
  }

  .os-select {
    display: none;
  }
}
</style>
