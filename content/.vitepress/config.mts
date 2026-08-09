import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig, type HeadConfig } from 'vitepress'
import { loadFacts, substituteFacts } from './facts.mts'
import { osContainer, SUPPORTED_OS } from './os-container.mts'
import { sidebarEn, sidebarDe } from './sidebar.mts'

const facts = loadFacts()

// Single source, shared with the shell scripts and the pages. See facts/project.yaml.
const REPO = facts.project.repo
const BASE = '/thi-linux-macos-setup/'

/** The content root, so transformPageData can read a page's own source. */
const CONTENT_DIR = fileURLToPath(new URL('..', import.meta.url))

/*
 * Absolute address of the deployed site. Not in facts/ with the campus values:
 * those describe THI's infrastructure and are checked against it, and
 * check-fact-urls.sh would ask this one whether the site is up, which is a
 * different question from whether a documented value still holds.
 * content/public/index.html carries its own copy because the facts
 * substitution only ever sees markdown.
 */
const SITE = 'https://hutzelmann.github.io' + BASE

const SITE_NAME = 'THI Linux & macOS Setup'

const SITE_DESCRIPTION =
  'Community setup notes for Linux and macOS at Technische Hochschule Ingolstadt. '
  + 'Unofficial, not THI IT Support.'

/*
 * Link preview image, 1200x630. Source and render command: tools/og-image.svg.
 * One image for both locales; its last line is bilingual for that reason.
 */
const OG_IMAGE = SITE + 'og.png'

const CC0 = 'https://creativecommons.org/publicdomain/zero/1.0/'

/** First step of the breadcrumb trail, in the language of the page. */
const HOME_LABEL: Record<string, string> = { en: 'Home', de: 'Start' }

const OG_IMAGE_ALT = {
  en: 'Linux & macOS @ THI. Community setup notes for Technische Hochschule Ingolstadt.',
  de: 'Linux & macOS @ THI. Einrichtungsnotizen für die Technische Hochschule Ingolstadt.'
}


/**
 * A page's source path as the deployed URL, relative to the site root.
 *
 * `en/wifi/index.md` is served at `en/wifi/` and `en/vpn/openfortivpn.md` at
 * `en/vpn/openfortivpn`. Canonicals and hreflang pairs are built from this, so
 * the two forms have to agree with what the server actually serves.
 */
function urlPath(relativePath: string): string {
  return relativePath.replace(/index\.md$/, '').replace(/\.md$/, '')
}

/**
 * The same page in the other language, or null while it does not exist yet.
 *
 * Both locales mirror each other path for path, so this is one path segment
 * swapped. It is checked against the filesystem rather than assumed, because
 * emitting an hreflang pair pointing at a 404 is worse than emitting none.
 */
function counterpart(relativePath: string): string | null {
  const [locale, ...rest] = relativePath.split('/')
  const other = locale === 'en' ? 'de' : 'en'
  const candidate = [other, ...rest].join('/')
  return existsSync(join(CONTENT_DIR, candidate)) ? candidate : null
}

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
    // Base-aware: the site is served from a subpath, so a root-relative
    // href would miss. The SVG carries its own light and dark palette.
    // The .ico is rendered by hand from favicon.svg, palette inlined:
    //   rsvg-convert -w N -h N favicon-static.svg -o icon-N.png   (N = 16, 32, 48)
    //   magick icon-16.png icon-32.png icon-48.png favicon.ico
    // The .ico goes first so Safari below 16 and old Edge, which ignore the
    // SVG, still find an icon. Everything newer prefers the typed SVG below.
    ['link', { rel: 'icon', sizes: '32x32', href: BASE + 'favicon.ico' }],
    ['link', { rel: 'icon', type: 'image/svg+xml', href: BASE + 'favicon.svg' }],
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

  /*
   * Which operating systems a page actually has blocks for, read out of the
   * page itself rather than taken from its `os:` frontmatter. The two can
   * disagree, and one of them is a hand-typed declaration: a page can name
   * macOS and carry no macOS block. The marker under the heading says this out
   * loud to the reader, so it has to come from the blocks and not from an
   * intention. Nothing to keep in step by hand, and a block removed in a commit
   * disappears from the sentence in the same commit.
   */
  transformPageData(pageData) {
    const file = join(CONTENT_DIR, pageData.relativePath)
    if (!existsSync(file)) return
    const blocks = readFileSync(file, 'utf8').matchAll(/^::: os (\w+)/gm)
    const found = [...new Set([...blocks].map((m) => m[1]))]
    // Declaration order, not order of appearance, so the sentence reads the
    // same on every page.
    pageData.frontmatter.osBlocks = SUPPORTED_OS.filter((os) => found.includes(os))
  },

  /*
   * VitePress emits neither a canonical URL nor hreflang pairs, and this site
   * needs both. One page is reachable at several addresses: the root chooser
   * links to /en/ and /de/ with an `?os=` query attached, and the two locales
   * are the same page in two languages. The canonical names one address; the
   * hreflang pair says the other locale is a translation rather than a copy.
   *
   * The operating system stays out of the path, deliberately. Roughly a third
   * of the content sits inside `::: os` blocks and the rest is shared, so a
   * path per system would triplicate the reasoning, the verification and the
   * quirks, six ways once German is counted, and set three near-identical URLs
   * against each other. It is a reader's preference, carried in `?os=` and in
   * localStorage, and the canonical above is what keeps that out of the index.
   *
   * The pair is emitted only where the counterpart file actually exists. Both
   * locales carry every page (AGENTS.md, "Languages"), so in a passing build
   * that is every page; the guard is there for the moment between an English
   * page being added and its German counterpart landing.
   */
  transformHead({ pageData, title, description }): HeadConfig[] {
    const relativePath = pageData.relativePath
    const locale = relativePath.split('/')[0]
    // 404.md and anything else outside a locale directory.
    if (locale !== 'en' && locale !== 'de') return []

    const self = SITE + urlPath(relativePath)
    const other = counterpart(relativePath)
    const otherLocale = locale === 'en' ? 'de' : 'en'
    const isLanding = urlPath(relativePath) === `${locale}/`

    const tags: HeadConfig[] = [
      ['link', { rel: 'canonical', href: self }],
      ['link', { rel: 'alternate', hreflang: locale, href: self }]
    ]

    if (other) {
      tags.push([
        'link',
        { rel: 'alternate', hreflang: otherLocale, href: SITE + urlPath(other) }
      ])
    }

    // The root asks language and operating system instead of guessing either.
    tags.push(['link', { rel: 'alternate', hreflang: 'x-default', href: SITE }])

    /*
     * Open Graph and Twitter cards. Pages here get pasted into chats between
     * people trying to fix the same thing, and a bare URL says nothing about
     * which of them it is. The values are the page's own title and description,
     * so there is no second copy to keep in step.
     */
    tags.push(
      ['meta', { property: 'og:type', content: isLanding ? 'website' : 'article' }],
      ['meta', { property: 'og:site_name', content: SITE_NAME }],
      ['meta', { property: 'og:title', content: title }],
      ['meta', { property: 'og:description', content: description ?? '' }],
      ['meta', { property: 'og:url', content: self }],
      ['meta', { property: 'og:locale', content: locale === 'en' ? 'en_US' : 'de_DE' }],
      ['meta', { property: 'og:image', content: OG_IMAGE }],
      ['meta', { property: 'og:image:type', content: 'image/png' }],
      ['meta', { property: 'og:image:width', content: '1200' }],
      ['meta', { property: 'og:image:height', content: '630' }],
      ['meta', { property: 'og:image:alt', content: OG_IMAGE_ALT[locale] }],
      ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
      ['meta', { name: 'twitter:title', content: title }],
      ['meta', { name: 'twitter:description', content: description ?? '' }],
      ['meta', { name: 'twitter:image', content: OG_IMAGE }]
    )

    if (other) {
      tags.push([
        'meta',
        {
          property: 'og:locale:alternate',
          content: otherLocale === 'en' ? 'en_US' : 'de_DE'
        }
      ])
    }

    /*
     * Structured data. Two things here are worth stating rather than implying:
     *
     * `dateModified` is the file's last edit, taken from git, and never
     * `lastChecked`. A check is a person running the steps on hardware; an edit
     * is an edit. Feeding one into a field named after the other would export
     * the exact claim this project refuses to make on its own pages.
     *
     * The author is this project, not the university. Nothing here speaks for
     * THI, and a publisher field naming it would say otherwise to every machine
     * that reads the page.
     */
    /*
     * Two levels, not three. The sidebar groups ("Network", "Printing and
     * files") have no page of their own, and a trail entry either carries the
     * URL of the thing it names or does not belong in it.
     */
    const crumbs = [{ name: HOME_LABEL[locale], item: SITE + locale + '/' }]
    if (!isLanding) {
      crumbs.push({ name: pageData.frontmatter.title ?? title, item: self })
    }

    const page = {
      // A page that declares `os` carries steps to run on a machine. That is
      // what separates the instructions here from the pages about the project.
      '@type': Array.isArray(pageData.frontmatter.os) ? 'TechArticle' : 'WebPage',
      '@id': self + '#page',
      url: self,
      name: pageData.frontmatter.title ?? title,
      headline: pageData.frontmatter.title ?? title,
      description: description ?? '',
      inLanguage: locale,
      isPartOf: { '@id': SITE + '#website' },
      breadcrumb: { '@id': self + '#breadcrumb' },
      license: CC0,
      author: { '@id': SITE + '#project' },
      ...(pageData.lastUpdated
        ? { dateModified: new Date(pageData.lastUpdated).toISOString() }
        : {})
    }

    tags.push([
      'script',
      { type: 'application/ld+json' },
      JSON.stringify({
        '@context': 'https://schema.org',
        '@graph': [
          {
            '@type': 'WebSite',
            '@id': SITE + '#website',
            url: SITE,
            name: SITE_NAME,
            description: SITE_DESCRIPTION,
            inLanguage: ['en', 'de'],
            license: CC0,
            publisher: { '@id': SITE + '#project' }
          },
          {
            '@type': 'Organization',
            '@id': SITE + '#project',
            name: SITE_NAME,
            url: SITE,
            description:
              'A community-maintained, unofficial collection of setup notes. '
              + 'Not affiliated with Technische Hochschule Ingolstadt.'
          },
          isLanding ? { ...page, '@type': 'CollectionPage' } : page,
          {
            '@type': 'BreadcrumbList',
            '@id': self + '#breadcrumb',
            itemListElement: crumbs.map((crumb, i) => ({
              '@type': 'ListItem',
              position: i + 1,
              name: crumb.name,
              item: crumb.item
            }))
          }
        ]
      })
    ])

    return tags
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
         * The dev server never gets there; Vite answers `/` with its own app
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

  // Both locales live in a subdirectory, and there is no `root` locale, so that
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
        /*
         * No `nav`. Every page is one click away in the sidebar, so a navbar
         * copy of three of them was a second, shorter table of contents that
         * had to be kept in step with the first by hand. The room they took
         * goes to the search box instead, which is how people arrive here,
         * usually with something already broken. See theme/navbar.css.
         */
        sidebar: sidebarEn,
        editLink: {
          pattern: `https://github.com/${REPO}/edit/main/content/:path`,
          text: 'Edit this page on GitHub'
        },
        lastUpdatedText: 'Last edited',
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
        /*
         * No `nav`. Every page is one click away in the sidebar, so a navbar
         * copy of three of them was a second, shorter table of contents that
         * had to be kept in step with the first by hand. The room they took
         * goes to the search box instead, which is how people arrive here,
         * usually with something already broken. See theme/navbar.css.
         */
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
    /*
     * Read by PageActions.vue and PageStatus.vue. Both are documented values
     * that live in facts/project.yaml, so they reach the browser through here
     * rather than being written a second time in a component.
     */
    repo: REPO,
    staleAfterDays: Number(facts.project.stale_after_days),

    // Named back at the reader, the same way the OS blocks in a page are. All
    // variants stay in the DOM and os.css shows the matching one, so the separator
    // is there for the reading that never applies CSS and sees both at once.
    siteTitle:
      'THI <span class="os-word" data-os-word="linux">Linux</span>'
      + '<span class="os-sep" aria-hidden="true">, </span>'
      + '<span class="os-word" data-os-word="macos">macOS</span> Setup',
    search: {
      provider: 'local',
      options: {
        /*
         * The search index is built from markdown on disk, which still holds
         * ${facts.*} tokens rather than the values they render to. Without this,
         * every hostname, queue name and certificate authority is missing from
         * the index, and those are exactly the strings someone pastes into
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
    hostname: SITE
  }
})
