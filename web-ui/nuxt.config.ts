export default defineNuxtConfig({
  compatibilityDate: '2026-08-17',
  devtools: { enabled: false },
  future: {
    compatibilityVersion: 4,
  },
  srcDir: '.',
  serverDir: './server',
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    // Server-only. Every key is overridable at runtime via NUXT_* env vars
    // (nested keys map to underscores: cmangos.db.host ← NUXT_CMANGOS_DB_HOST).
    // In the docker stack these are wired from the repo's .env values
    // (MANGOS_DBHOST / MANGOS_DBUSER / MANGOS_DBPASS / WOW_VERSION) by the
    // compose service — see web-ui/.env.example.
    cmangos: {
      // One of: classic | tbc | wotlk. Selects the account defaults and the
      // derived database names (<core>realmd / <core>characters).
      core: '',
      db: {
        host: '',
        port: 3306,
        user: '',
        password: '',
        // Derived from `core` when empty. Override only for non-standard
        // deployments whose databases don't follow the CMaNGOS naming.
        realmdName: '',
        charactersName: '',
      },
    },
    session: {
      // h3 sealed-cookie session (useSession). MUST be at least 32 chars —
      // generate with e.g. `openssl rand -base64 48`.
      password: '',
      maxAge: 60 * 60 * 24 * 7, // seconds; 7 days
      // Set true only when the UI is served over HTTPS. The docker stack is
      // plain HTTP on a LAN, so the default must stay false there.
      secureCookie: false,
    },
  },
})
