import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import OSSwitcher from './OSSwitcher.vue'
import NavExtra from './NavExtra.vue'
import PageStatus from './PageStatus.vue'
import PageActions from './PageActions.vue'
import ScriptDownload from './ScriptDownload.vue'
import FactCard from './FactCard.vue'
import FactDeck from './FactDeck.vue'
import './os.css'
import './navbar.css'
import './hero.css'
import './landing.css'
import './doc-footer.css'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      // OS switcher and GitHub link together, so their order is ours to set.
      // See NavExtra.vue.
      'nav-bar-content-after': () => h(NavExtra),
      // Rendered twice, and the stylesheet decides which one is visible:
      // VitePress only shows the aside column from 1280px up, so a narrow
      // window would otherwise lose the marker entirely.
      'aside-outline-before': () => h(PageStatus, { variant: 'aside' }),
      'doc-before': () => h(PageStatus, { variant: 'inline' }),
      // doc-footer-before, not doc-after: the row sits above the pager, and
      // doc-footer.css hides the default theme's duplicate of it.
      'doc-footer-before': () => h(PageActions)
    })
  },
  enhanceApp({ app }) {
    app.component('OSSwitcher', OSSwitcher)
    // Used directly in markdown, so they must be globally registered.
    app.component('ScriptDownload', ScriptDownload)
    app.component('FactCard', FactCard)
    app.component('FactDeck', FactDeck)
  }
} satisfies Theme
