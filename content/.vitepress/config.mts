import { defineConfig } from 'vitepress'
import { loadFacts, substituteFacts } from './facts.mts'
import { osContainer } from './os-container.mts'
import { sidebarEn, sidebarDe } from './sidebar.mts'

const facts = loadFacts()

const REPO = 'hutzelmann/thi-linux-macos-setup'

export default defineConfig({
  title: 'THI Linux & macOS Setup',
  description:
    'Community setup notes for Linux and macOS at Technische Hochschule Ingolstadt. Unofficial, not THI IT Support.',
  base: '/thi-linux-macos-setup/',
  cleanUrls: true,
  lastUpdated: true,
  // A dead link is a broken instruction. Fail the build, don't warn.
  ignoreDeadLinks: false,

  head: [
    // Blocking, pre-hydration: decide the OS before first paint so Mac visitors
    // never see Arch flash past. Resolution order is documented in the theme.
    [
      'script',
      {},
      `(()=>{try{
        const p=new URLSearchParams(location.search).get('os');
        const stored=localStorage.getItem('os');
        const mac=/Mac|iPhone|iPad/.test(navigator.platform||navigator.userAgent);
        const os=p||stored||(mac?'macos':'arch');
        document.documentElement.dataset.os=os;
        if(p)localStorage.setItem('os',p);
      }catch(e){document.documentElement.dataset.os='arch'}})()`
    ]
  ],

  markdown: {
    config(md) {
      osContainer(md)
    }
  },

  // Runs before markdown-it, so facts land inside code fences too.
  transformPageData(pageData) {
    return pageData
  },

  vite: {
    plugins: [
      {
        name: 'facts-substitution',
        enforce: 'pre',
        transform(code, id) {
          if (!id.endsWith('.md')) return
          return { code: substituteFacts(code, facts, id), map: null }
        }
      }
    ]
  },

  locales: {
    root: {
      label: 'English',
      lang: 'en',
      dir: 'en',
      themeConfig: {
        nav: [
          { text: 'Start here', link: '/en/start/new-machine' },
          { text: 'Page status', link: '/en/about/status' },
          { text: 'How this works', link: '/en/about/how-this-works' }
        ],
        sidebar: sidebarEn,
        editLink: {
          pattern: `https://github.com/${REPO}/edit/main/content/:path`,
          text: 'Edit this page on GitHub'
        },
        lastUpdatedText: 'Page last edited',
        outline: { level: [2, 3], label: 'On this page' },
        docFooter: { prev: 'Previous', next: 'Next' },
        footer: {
          message:
            'Community-maintained and unofficial. Not affiliated with, endorsed by, or speaking for THI IT. Official support: <a href="https://help.thi.de/">help.thi.de</a>',
          copyright: 'Released into the public domain under CC0 1.0.'
        }
      }
    },
    de: {
      label: 'Deutsch',
      lang: 'de',
      dir: 'de',
      themeConfig: {
        nav: [
          { text: 'WLAN', link: '/de/wifi/' },
          { text: 'Alle Seiten (englisch)', link: '/en/about/status' }
        ],
        sidebar: sidebarDe,
        editLink: {
          pattern: `https://github.com/${REPO}/edit/main/content/:path`,
          text: 'Diese Seite auf GitHub bearbeiten'
        },
        lastUpdatedText: 'Zuletzt bearbeitet',
        outline: { level: [2, 3], label: 'Auf dieser Seite' },
        docFooter: { prev: 'Zurück', next: 'Weiter' },
        footer: {
          message:
            'Von der Community gepflegt, inoffiziell. Keine Verbindung zur THI-IT, kein offizieller Support. Offizieller Support: <a href="https://help.thi.de/">help.thi.de</a>',
          copyright: 'Gemeinfrei veröffentlicht unter CC0 1.0.'
        }
      }
    }
  },

  themeConfig: {
    search: {
      provider: 'local',
      options: {
        // Typo tolerance matters more than precision here: people arrive with
        // "eduraom" and a broken laptop. Kept low so package and flag names
        // don't turn into noise.
        miniSearch: {
          searchOptions: { fuzzy: 0.2, prefix: true }
        },
        locales: {
          de: {
            translations: {
              button: { buttonText: 'Suchen', buttonAriaLabel: 'Suchen' },
              modal: {
                displayDetails: 'Details anzeigen',
                resetButtonTitle: 'Suche zurücksetzen',
                backButtonTitle: 'Suche schließen',
                noResultsText: 'Keine Ergebnisse für',
                footer: {
                  selectText: 'auswählen',
                  navigateText: 'navigieren',
                  closeText: 'schließen'
                }
              }
            }
          }
        }
      }
    },
    socialLinks: [{ icon: 'github', link: `https://github.com/${REPO}` }]
  },

  sitemap: {
    hostname: 'https://hutzelmann.github.io/thi-linux-macos-setup/'
  }
})
