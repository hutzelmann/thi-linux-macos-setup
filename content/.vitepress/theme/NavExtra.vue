<script setup lang="ts">
import OSSwitcher from './OSSwitcher.vue'

const REPO = 'https://github.com/hutzelmann/thi-linux-macos-setup'
</script>

<!--
  The navbar order is appearance | OS | GitHub, and VitePress offers no slot
  between the appearance toggle and the social links. So the built-in social
  links are switched off in config and the GitHub link is rendered here instead,
  after the OS switcher, where it belongs.

  The OS switcher stays visible at every width: Debian users are silently given
  the Arch default (a browser cannot reveal a distribution), so the control that
  corrects it must never be behind a menu. The GitHub link may hide on narrow
  screens; it is a convenience, not a correction.
-->
<template>
  <div class="nav-extra">
    <span class="divider" aria-hidden="true" />
    <OSSwitcher />
    <span class="divider github-divider" aria-hidden="true" />
    <a class="github" :href="REPO" target="_blank" rel="noreferrer" aria-label="GitHub repository">
      <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
        <path
          fill="currentColor"
          d="M12 .3a12 12 0 0 0-3.8 23.4c.6.1.8-.3.8-.6v-2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1-.7.1-.7.1-.7 1.2.1 1.8 1.2 1.8 1.2 1 1.8 2.8 1.3 3.5 1 0-.8.4-1.3.7-1.6-2.7-.3-5.5-1.3-5.5-6 0-1.2.5-2.3 1.3-3.1-.2-.4-.6-1.6.1-3.2 0 0 1-.3 3.3 1.2a11.5 11.5 0 0 1 6 0C17.3 4.8 18.3 5 18.3 5c.7 1.6.3 2.8.1 3.2.8.8 1.3 1.9 1.3 3.2 0 4.6-2.8 5.6-5.5 5.9.5.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6A12 12 0 0 0 12 .3Z"
        />
      </svg>
    </a>
  </div>
</template>

<style scoped>
/*
 * Every gap is set here rather than inherited. The default theme gives the
 * appearance toggle and the social links their own asymmetric margins, which is
 * fine when they sit at the end of the bar and visibly wrong once something is
 * placed between them.
 *
 * One spacing value on both sides of each divider, and the same value again
 * between this group and the appearance toggle to its left.
 */
.nav-extra {
  display: flex;
  align-items: center;
  margin-left: 12px;
}

.nav-extra > * + * {
  margin-left: 12px;
}

.divider {
  flex: none;
  width: 1px;
  height: 24px;
  background-color: var(--vp-c-divider);
}

.github {
  display: flex;
  align-items: center;
  color: var(--vp-c-text-2);
  transition: color 0.25s;
}

.github:hover {
  color: var(--vp-c-text-1);
}

@media (max-width: 767px) {
  /* Keep the OS switcher; drop the link and the separator before it. */
  .github,
  .github-divider {
    display: none;
  }
}
</style>
