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
    <div class="head">
      <div class="meta">
        <code>{{ file }}</code>
        <span class="does">{{ does }}</span>
      </div>
      <a class="button" :href="href" :download="file">
        {{ de ? 'Herunterladen' : 'Download' }}
      </a>
    </div>

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
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
}

.meta {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 10px;
  align-items: baseline;
}

.meta code {
  font-size: 14px;
  font-weight: 600;
}

.does {
  font-size: 14px;
  color: var(--vp-c-text-2);
}

.button {
  flex: none;
  padding: 6px 18px;
  border: 1px solid var(--vp-c-brand-1);
  border-radius: 18px;
  font-size: 14px;
  font-weight: 500;
  color: var(--vp-c-brand-1);
  text-decoration: none;
  transition: background-color 0.2s, color 0.2s;
}

.button:hover {
  background: var(--vp-c-brand-1);
  color: var(--vp-c-bg);
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
