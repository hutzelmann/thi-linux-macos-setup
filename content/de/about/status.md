---
title: Seitenstatus
description: Welche Seiten jemand auf einem echten Rechner geprüft hat, auf welchem Betriebssystem, und was zu tun ist.
translatedFrom: e986c0fac43b5e06e0e46c5d588c80d00a566b5e
---

<script setup>
import { onMounted, ref } from 'vue'
import { useData, withBase } from 'vitepress'
// Ein Ladeprogramm für beide Sprachen, importiert von der englischen Seite. Es liest die
// Seiten selbst und filtert nach Sprache, eine zweite Kopie hier hätte nur die Chance,
// von der ersten abzuweichen.
import { data as pages } from '../../en/about/status.data.mts'
import { daysSince, exactDate, relativeDays } from '../../.vitepress/theme/relative-time'

const { lang, theme } = useData()

const OS_NAMES = { arch: 'Arch', debian: 'Debian', macos: 'macOS' }
const COLUMNS = ['arch', 'debian', 'macos']

const de = pages.filter(p => p.locale === 'de')

// Gezählt wird je Seite und Betriebssystem, denn das ist die Einheit, die eine Prüfung
// abdeckt. Drei Blöcke auf einer Seite sind drei getrennte Dinge zum Ausführen.
const pairs = de.flatMap(p => p.os.map(os => p.checked[os]))
const counts = {
  checked: pairs.filter(Boolean).length,
  unchecked: pairs.filter(d => !d).length
}

// Im Browser gezählt, nie beim Bauen. Siehe relative-time.ts.
const now = ref(null)
onMounted(() => { now.value = Date.now() })

// Dieselbe Formulierung wie der Marker auf jeder Seite und wie die Zeile "Zuletzt
// bearbeitet" im Fuß: eine Art, auf der ganzen Seite zu sagen, wie lange es her ist.
// Der genaue Tag steht im Tooltip, es geht also nichts verloren.
function label(date) {
  if (!date) return 'noch nicht geprüft'
  if (now.value === null) return date
  const days = daysSince(date, now.value)
  return days === null ? date : relativeDays(days, lang.value)
}

function exact(date) {
  return date ? exactDate(date, lang.value) : undefined
}

// Jenseits des Horizonts aus facts/project.yaml. Weiterhin eine Prüfung, nur leiser.
function stale(date) {
  if (!date || now.value === null) return false
  const days = daysSince(date, now.value)
  return days !== null && days > theme.value.staleAfterDays
}
</script>

# Seitenstatus

Aus den Seiten selbst erzeugt. Nichts hier wird von Hand gepflegt, es kann also nicht
gegenüber dem Inhalt veralten.

<div class="status-summary">
  <span><strong>{{ counts.checked }}</strong> auf einem echten Rechner geprüft</span>
  <span><strong>{{ counts.unchecked }}</strong> noch nicht geprüft</span>
</div>

Diese Zahlen zählen Seite und Betriebssystem zusammen, nicht Seiten. Jede Seite hier gibt
Arch, Debian und macOS unterschiedliche Schritte. Ihr auf einem davon zu folgen, ist ein
Beleg für dieses eine und sagt über die anderen beiden nichts.

## Was die zwei Zustände bedeuten

Es gibt keinen dritten Zustand und kein Feld, das einen benennt. Eine Seite trägt für ein
Betriebssystem ein Datum, oder sie trägt keines.

**Ein Datum.** Jemand ist an diesem Tag den Schritten dieses Betriebssystems gefolgt und
hat berichtet, was passiert ist. Das Datum ist die ganze Aussage: Es sagt, wann jemand
hingesehen hat, nicht dass die Seite heute stimmt.

**Noch nicht geprüft.** Die Schritte sind aufgeschrieben und ihre Werte kommen aus der
gemeinsamen Fakten-Datei, Hostnamen und Warteschlangennamen stimmen also mit allen anderen
Seiten überein. Was fehlt, ist jemand, der bestätigt, dass sie auf echter Hardware
funktionieren.

Jede Seite zeigt ihren Zustand als kleinen Punkt neben dem Text, und er folgt dem in der
Navigationsleiste gewählten Betriebssystem: Wer von Arch auf macOS wechselt, sieht den
Marker mit den Schritten wechseln. Seiten ohne etwas, das auf einem Rechner auszuführen
wäre, also die beiden Seiten über das Projekt, tragen einen grauen Punkt und sagen das.
Sie stehen unten nicht in der Liste.

Daten werden angezeigt, wie lange sie her sind, genau wie die Zeile "Zuletzt bearbeitet"
am Fuß jeder Seite. Der genaue Tag steht im Tooltip. Jenseits von
${facts.project.stale_after_days} Tagen wird eine Prüfung leiser dargestellt. Das ist kein
dritter Zustand und keine Behauptung, dass die Seite an diesem Tag falsch wurde. Es sagt
nur, dass seither niemand hingesehen hat, und das ist es wert, gewusst zu werden, bevor du
der Seite folgst.

## Alle Seiten

In der Reihenfolge von [Ein neuer Rechner am Campus](/de/start/new-machine), also in der
Reihenfolge, in der man sie tatsächlich durchgeht. Seiten, die dort nicht verlinkt sind,
stehen am Ende.

<table class="status-table">
  <thead>
    <tr>
      <th>Seite</th>
      <th v-for="os in COLUMNS" :key="os">{{ OS_NAMES[os] }}</th>
    </tr>
  </thead>
  <tbody>
    <tr v-for="p in de" :key="p.url">
      <td><a :href="withBase(p.url)">{{ p.title }}</a></td>
      <td v-for="os in COLUMNS" :key="os">
        <span v-if="!p.os.includes(os)" class="absent">nicht dokumentiert</span>
        <span
          v-else
          class="pill"
          :data-checked="p.checked[os] ? '' : null"
          :data-stale="stale(p.checked[os]) ? '' : null"
          :title="exact(p.checked[os])"
        >
          {{ label(p.checked[os]) }}
        </span>
      </td>
    </tr>
  </tbody>
</table>

## Das Nützlichste, was du tun kannst

Nimm eine Seite ohne Datum für das System, das du benutzt, folge ihr auf deinem eigenen
Rechner und
[reiche eine Prüfmeldung ein](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml),
in der steht, was passiert ist, auch "Schritt 3 stimmt nicht, es ist in Wirklichkeit X".
Das Formular fragt, welches Betriebssystem du verwendet hast, und diese Antwort
entscheidet, wo das Datum landet.

Das ist mehr wert als neue Seiten. Eine Seite, der niemand gefolgt ist, ist eine Vermutung
mit guter Formatierung.

<style scoped>
.status-summary {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  margin: 24px 0;
  padding: 16px;
  border-radius: 8px;
  background: var(--vp-c-default-soft);
  font-size: 14px;
}

.status-table {
  display: table;
  width: 100%;
}

.pill {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  background: var(--vp-c-default-soft);
  font-size: 12px;
  white-space: nowrap;
}

.pill[data-checked] { background: var(--vp-c-success-soft); }
.pill[data-checked][data-stale] { background: var(--vp-c-warning-soft); }

/* Ein Betriebssystem ohne Block auf der Seite ist keine offene Prüfung. */
.absent {
  font-size: 12px;
  color: var(--vp-c-text-3);
}
</style>
