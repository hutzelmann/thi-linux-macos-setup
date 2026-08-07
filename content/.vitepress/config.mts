import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitepress'
import { loadFacts, substituteFacts } from './facts.mts'
import { osContainer } from './os-container.mts'
import { sidebarEn, sidebarDe } from './sidebar.mts'

const facts = loadFacts()

const REPO = 'hutzelmann/thi-linux-macos-setup'
const BASE = '/thi-linux-macos-setup/'

export default defineConfig({
  title: 'THI Linux & macOS Setup',
  description:
    'Community setup notes for Linux and macOS at Technische Hochschule Ingolstadt. Unofficial, not THI IT Support.',
  base: BASE,
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
      },
      {
        /*
         * In a production build the site root comes from public/index.html.
         * The dev server never gets there — Vite answers `/` with its own app
         * shell, which then renders the 404 page because no route matches.
         *
         * Serving the same file in dev keeps the two identical. A root that
         * works only after a build is the kind of difference that costs the
         * next person an afternoon.
         */
        name: 'root-locale-chooser-in-dev',
        configureServer(server) {
          const chooser = fileURLToPath(new URL('../public/index.html', import.meta.url))
          server.middlewares.use((req, res, next) => {
            const path = (req.url ?? '').split('?')[0]
            if (path === BASE || path === '/' || path === `${BASE}index.html`) {
              res.setHeader('Content-Type', 'text/html; charset=utf-8')
              res.end(readFileSync(chooser, 'utf8'))
              return
            }
            next()
          })
        }
      }
    ]
  },

  // Both locales live in a subdirectory — there is no `root` locale — so that
  // /en/ and /de/ mirror each other exactly. That symmetry is what lets the
  // language switcher, the sidebar and the translation-staleness check all work
  // by swapping one path segment. The cost is that `/` needs its own redirect,
  // which content/public/index.html provides.
  locales: {
    en: {
      label: 'English',
      lang: 'en',
      link: '/en/',
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
            'Community-maintained and unofficial. Not affiliated with, endorsed by, or speaking for THI IT. '
            + 'Official: <a href="https://www.thi.de/service/it-service/">THI IT service</a> · '
            + '<a href="https://help.thi.de/help/de-de">knowledge base</a> · '
            + '<a href="mailto:support@thi.de">support@thi.de</a>',
          copyright: 'Released into the public domain under CC0 1.0.'
        }
      }
    },
    de: {
      label: 'Deutsch',
      lang: 'de',
      link: '/de/',
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
            'Von der Community gepflegt, inoffiziell. Keine Verbindung zur THI-IT, kein offizieller Support. '
            + 'Offiziell: <a href="https://www.thi.de/service/it-service/">THI IT-Service</a> · '
            + '<a href="https://help.thi.de/help/de-de">Wissensdatenbank</a> · '
            + '<a href="mailto:support@thi.de">support@thi.de</a>',
          copyright: 'Gemeinfrei veröffentlicht unter CC0 1.0.'
        }
      }
    }
  },

  themeConfig: {
    search: {
      provider: 'local',
      options: {
        /*
         * The search index is built from markdown on disk, which still holds
         * ${facts.*} tokens rather than the values they render to. Without this,
         * every hostname, queue name and certificate authority is missing from
         * the index — and those are exactly the strings someone pastes into
         * search when something is broken. Substitute before indexing.
         */
        _render(src, env, md) {
          return md.render(substituteFacts(src, facts, env.relativePath ?? '<search>'), env)
        },
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
    // No socialLinks here on purpose: the built-in ones render before the
    // navbar's after-slot, which would put GitHub ahead of the OS switcher.
    // Both are rendered together in theme/NavExtra.vue instead.
  },

  sitemap: {
    hostname: 'https://hutzelmann.github.io/thi-linux-macos-setup/'
  }
})
