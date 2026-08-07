import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import OSSwitcher from './OSSwitcher.vue'
import NavExtra from './NavExtra.vue'
import PageStatus from './PageStatus.vue'
import ReportButton from './ReportButton.vue'
import './os.css'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      // OS switcher and GitHub link together, so their order is ours to set.
      // See NavExtra.vue.
      'nav-bar-content-after': () => h(NavExtra),
      'doc-before': () => h(PageStatus),
      'doc-after': () => h(ReportButton)
    })
  },
  enhanceApp({ app }) {
    app.component('OSSwitcher', OSSwitcher)
  }
} satisfies Theme
