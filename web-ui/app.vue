<script setup lang="ts">
useHead({
  htmlAttrs: { lang: 'en' },
  titleTemplate: (t) =>
    t ? `${t} · cmangos-docker` : 'cmangos-docker — server portal',
  meta: [
    {
      name: 'description',
      content:
        'Web portal for a CMaNGOS docker realm: account creation, login and live server status.',
    },
  ],
})

const { account, loaded, refresh, logout } = useAuth()

// Resolve the session once per app lifecycle (SSR with forwarded cookie,
// again on client hydration). Cookie-seal read only, no DB hit.
await refresh()

async function onLogout() {
  await logout()
  await navigateTo('/')
}
</script>

<template>
  <div>
    <header class="site-header">
      <div class="container site-header__row">
        <NuxtLink to="/" class="brand">
          <span class="brand-mark" aria-hidden="true" />
          <span class="brand-name">cmangos<em>-docker</em></span>
        </NuxtLink>

        <nav class="site-nav" aria-label="Main">
          <template v-if="loaded && account">
            <span class="site-nav__who">
              Hail, <strong>{{ account.username }}</strong>
            </span>
            <button type="button" class="btn btn--ghost btn--sm" @click="onLogout">
              Log out
            </button>
          </template>
          <template v-else-if="loaded">
            <NuxtLink to="/login">Log in</NuxtLink>
            <NuxtLink to="/register" class="btn btn--sm">Create account</NuxtLink>
          </template>
        </nav>
      </div>
    </header>

    <main class="container">
      <NuxtPage />
    </main>

    <footer class="site-footer">
      <div class="container">
        <p>
          A companion portal for CMaNGOS realms. Unofficial fan work — not
          affiliated with or endorsed by Blizzard Entertainment.
        </p>
      </div>
    </footer>
  </div>
</template>
