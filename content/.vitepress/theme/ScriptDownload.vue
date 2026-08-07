<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const props = defineProps<{
  /** Bundled file name, e.g. "vpn-verify.sh". */
  file: string
  /** What it does, one line. */
  does: string
  /** Set when the script changes system state, so the warning is honest. */
  sudo?: boolean
}>()

const { lang } = useData()
const de = computed(() => lang.value.startsWith('de'))
const href = computed(() => withBase(`/scripts/${props.file}`))

/*
 * Deliberately not a `curl … | sh` one-liner. Piping a script straight into a
 * shell means running something you have not read, and this project asks people
 * to trust it about their campus credentials. Download, look, then run.
 */
const commands = computed(() =>
  [
    `curl -fsSLO ${'https://hutzelmann.github.io/thi-linux-macos-setup'}/scripts/${props.file}`,
    de.value ? `less ${props.file}   # erst lesen` : `less ${props.file}   # read it first`,
    `sh ${props.file} --dry-run`,
    props.sudo ? `sh ${props.file}` : null
  ]
    .filter(Boolean)
    .join('\n')
)
</script>

<template>
  <div class="script-download">
    <!--
      Name and action on one line, description under it. The description is a
      sentence and will wrap; keeping it out of the same row stops it pushing
      the button onto a line of its own.
    -->
    <div class="head">
      <code class="name">{{ file }}</code>
      <a class="button" :href="href" :download="file">
        <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true">
          <path
            fill="currentColor"
            d="M8 1a.75.75 0 0 1 .75.75v6.44l2.22-2.22a.75.75 0 1 1 1.06 1.06l-3.5 3.5a.75.75 0 0 1-1.06 0l-3.5-3.5a.75.75 0 0 1 1.06-1.06l2.22 2.22V1.75A.75.75 0 0 1 8 1ZM2.75 12.5a.75.75 0 0 1 .75.75v.25h9v-.25a.75.75 0 0 1 1.5 0v.5a1.25 1.25 0 0 1-1.25 1.25h-9.5A1.25 1.25 0 0 1 2 13.75v-.5a.75.75 0 0 1 .75-.75Z"
          />
        </svg>
        {{ de ? 'Herunterladen' : 'Download' }}
      </a>
    </div>

    <p class="does">{{ does }}</p>

    <div class="language-bash"><pre><code>{{ commands }}</code></pre></div>

    <p class="note">
      <template v-if="de">
        Läuft eigenständig — die dokumentierten Werte und Hilfsfunktionen sind eingebaut,
        das Repository wird nicht gebraucht. <code>--dry-run</code> zeigt nur an, was
        passieren würde.
      </template>
      <template v-else>
        Runs on its own — the documented values and helpers are built in, no clone needed.
        <code>--dry-run</code> prints what it would do and changes nothing.
      </template>
    </p>
  </div>
</template>

<style scoped>
.script-download {
  margin: 24px 0;
  padding: 16px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  background: var(--vp-c-bg-soft);
}

.head {
  display: flex;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
}

.name {
  font-size: 14px;
  font-weight: 600;
}

.does {
  margin: 8px 0 0;
  font-size: 14px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}

/* Matches the default theme's brand button, so a download reads as the same
   kind of action as every other primary control on the site. */
.button {
  display: inline-flex;
  flex: none;
  gap: 6px;
  align-items: center;
  padding: 6px 16px;
  border: 1px solid var(--vp-c-brand-2);
  border-radius: 20px;
  background: var(--vp-c-brand-3);
  font-size: 14px;
  font-weight: 500;
  line-height: 22px;
  color: var(--vp-c-brand-1);
  text-decoration: none;
  white-space: nowrap;
  transition: border-color 0.2s, background-color 0.2s, color 0.2s;
}

.button:hover {
  border-color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-1);
  color: var(--vp-c-white);
}

.script-download :deep(pre) {
  margin: 14px 0 0;
  padding: 12px 14px;
  overflow-x: auto;
  border-radius: 6px;
  background: var(--vp-c-bg);
  font-size: 13px;
  line-height: 1.7;
}

.note {
  margin: 12px 0 0;
  font-size: 13px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}
</style>
