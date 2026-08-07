import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import OSSwitcher from './OSSwitcher.vue'
import PageStatus from './PageStatus.vue'
import ReportButton from './ReportButton.vue'
import './os.css'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      // Always visible: Debian users are silently given the Arch default
      // (there is no way to detect a distro from a browser), so the control
      // that corrects it must never be hidden behind a menu.
      'nav-bar-content-after': () => h(OSSwitcher),
      'doc-before': () => h(PageStatus),
      'doc-after': () => h(ReportButton)
    })
  },
  enhanceApp({ app }) {
    app.component('OSSwitcher', OSSwitcher)
  }
} satisfies Theme
