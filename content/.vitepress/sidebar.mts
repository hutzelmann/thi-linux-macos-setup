import type { DefaultTheme } from 'vitepress'

/**
 * Hand-written on purpose: ordering carries meaning here ("Getting started" first,
 * then the things people arrive broken about), and a generated tree cannot know
 * that. `npm run new-page` adds the entry for you, so contributors never edit
 * this by hand.
 */
export const sidebarEn: DefaultTheme.SidebarItem[] = [
  {
    text: 'Getting started',
    items: [{ text: 'A new machine on campus', link: '/en/start/new-machine' }]
  },
  {
    text: 'Network',
    items: [
      { text: 'Wi-Fi: eduroam and @thi', link: '/en/wifi/' },
      { text: 'VPN', link: '/en/vpn/openfortivpn' },
      { text: 'Wired ports and device registration', link: '/en/network/ethernet-802-1x' }
    ]
  },
  {
    text: 'Printing',
    items: [{ text: 'MARB-color', link: '/en/printing/marb-color' }]
  },
  {
    text: 'Files',
    items: [
      { text: 'Network shares (SMB)', link: '/en/shares/smb' },
      { text: 'OneDrive', link: '/en/files/onedrive' }
    ]
  },
  {
    text: 'Devices and systems',
    items: [
      { text: 'Projectors and external screens', link: '/en/devices/projectors' },
      { text: 'Windows in a VM', link: '/en/vm/windows' }
    ]
  },
  {
    text: 'Policy',
    items: [{ text: 'Secure device configuration', link: '/en/policy/secure-device-config' }]
  },
  {
    text: 'About',
    items: [
      { text: 'How this works', link: '/en/about/how-this-works' },
      { text: 'Page status', link: '/en/about/status' }
    ]
  }
]

/**
 * Shorter than the English tree on purpose: only translated pages appear here.
 * Linking to an untranslated page from the German sidebar would send readers to
 * a 404, worse than the honest gap, which the footer note explains.
 */
export const sidebarDe: DefaultTheme.SidebarItem[] = [
  {
    text: 'Netzwerk',
    items: [
      { text: 'WLAN: eduroam und @thi', link: '/de/wifi/' },
      { text: 'VPN', link: '/de/vpn/openfortivpn' }
    ]
  },
  {
    text: 'Drucken',
    items: [{ text: 'MARB-color', link: '/de/printing/marb-color' }]
  },
  {
    text: 'Weitere Themen',
    items: [{ text: 'Alle Seiten (englisch)', link: '/en/about/status' }]
  }
]
