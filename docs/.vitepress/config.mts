import { fileURLToPath, URL } from "node:url";
import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: "en-US",
  title: "CMaNGOS on Docker",
  description: "A collection of ready-to-use Docker images to host your WoW emulated private server wherever you want.",
  head: [
    // All browsers
    ["link", { rel: "icon", href: "/favicons/logo-16x16.png", sizes: "16x16", type: "image.png" }],
    ["link", { rel: "icon", href: "/favicons/logo-32x32.png", sizes: "32x32", type: "image.png" }],

    // Google & Android
    ["link", { rel: "icon", href: "/favicons/logo-48x48.png", sizes: "48x48", type: "image.png" }],
    ["link", { rel: "icon", href: "/favicons/logo-192x192.png", sizes: "192x192", type: "image.png" }],

    // iPad
    ["link", { rel: "apple-touch-icon", href: "/favicons/logo-167x167.png", sizes: "167x167", type: "image.png" }],

    // iPhone
    ["link", { rel: "apple-touch-icon", href: "/favicons/logo-180x180.png", sizes: "180x180", type: "image.png" }],

    ["script", {
      "src": "https://cloud.umami.is/script.js",
      "data-website-id": "46e2a043-e364-4c30-8561-45e4e4797398",
      "defer": ""
    }]
  ],
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: "/logo.png",
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/markdown-examples' }
    ],

    sidebar: [
      {
        text: 'Examples',
        items: [
          { text: 'Markdown Examples', link: '/markdown-examples' },
          { text: 'Runtime API Examples', link: '/api-examples' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Byloth/cmangos-docker' }
    ],
    footer: {
      message: `Rilasciato sotto
<a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noopener noreferrer nofollow">
  Licenza CC BY-SA 4.0</a>.`,
      copyright: `Copyright © 2014-${new Date().getFullYear()}
<a href="https://github.com/Byloth">
  Matteo Bilotta</a>.`
    }
  },
  vite: {
    resolve: {
      alias: { "@": fileURLToPath(new URL("../src", import.meta.url)) }
    }
  }
})
