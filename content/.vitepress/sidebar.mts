import type { DefaultTheme } from 'vitepress'

/**
 * Hand-written on purpose: ordering carries meaning here ("Getting started" first,
 * then the things people arrive broken about), and a generated tree cannot know
 * that. `npm run new-page` adds the entry for you, so contributors never edit
 * this by hand.
 */
export const sidebarEn: DefaultTheme.SidebarItem[] = [
  {
    // The device rules are the first step of setting a machine up, not a separate
    // topic: new-machine.md sends readers there before anything touches the
    // network. Keeping them together is why neither is a group of one.
    text: 'Getting started',
    items: [
      { text: 'A new machine on campus', link: '/en/start/new-machine' },
      { text: 'Secure device configuration', link: '/en/policy/secure-device-config' }
    ]
  },
  {
    text: 'Network',
    items: [
      { text: 'Wi-Fi: eduroam and @thi', link: '/en/wifi/' },
      { text: 'VPN', link: '/en/vpn/openfortivpn' },
      { text: 'Ethernet: 802.1X and registration', link: '/en/network/ethernet-802-1x' }
    ]
  },
  {
    // Printing sits here rather than under Network: the queue is an SMB share on
    // the same kind of server as the file shares, and people arrive looking for
    // "where do I get at campus stuff", not for a protocol.
    text: 'Printing and files',
    items: [
      { text: 'Printing', link: '/en/printing/' },
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
    text: 'About',
    items: [
      { text: 'How these pages are kept', link: '/en/about/how-this-works' },
      { text: 'Page status', link: '/en/about/status' }
    ]
  }
]

/**
 * The same entries in the same order as the English tree, because every page
 * exists in both languages (AGENTS.md rule 9). The language switcher, the two
 * sidebars and the hreflang pairs all work by swapping one path segment, so a
 * sidebar that offered less than the other would break that symmetry.
 */
export const sidebarDe: DefaultTheme.SidebarItem[] = [
  {
    text: 'Erste Schritte',
    items: [
      { text: 'Ein neuer Rechner am Campus', link: '/de/start/new-machine' },
      { text: 'Sichere Gerätekonfiguration', link: '/de/policy/secure-device-config' }
    ]
  },
  {
    text: 'Netzwerk',
    items: [
      { text: 'WLAN: eduroam und @thi', link: '/de/wifi/' },
      { text: 'VPN', link: '/de/vpn/openfortivpn' },
      { text: 'Ethernet: 802.1X und Registrierung', link: '/de/network/ethernet-802-1x' }
    ]
  },
  {
    text: 'Drucken und Dateien',
    items: [
      { text: 'Drucken', link: '/de/printing/' },
      { text: 'Netzlaufwerke (SMB)', link: '/de/shares/smb' },
      { text: 'OneDrive', link: '/de/files/onedrive' }
    ]
  },
  {
    text: 'Geräte und Systeme',
    items: [
      { text: 'Beamer und externe Bildschirme', link: '/de/devices/projectors' },
      { text: 'Windows in einer VM', link: '/de/vm/windows' }
    ]
  },
  {
    text: 'Über das Projekt',
    items: [
      { text: 'Wie diese Seiten gepflegt werden', link: '/de/about/how-this-works' },
      { text: 'Seitenstatus', link: '/de/about/status' }
    ]
  }
]
