<script setup lang="ts">
useHead({ title: 'Home' })

const { account } = useAuth()
</script>

<template>
  <div>
    <section class="hero">
      <p class="eyebrow">Server portal</p>
      <h1 class="hero-title">Answer the call.</h1>
      <p class="hero-sub">
        Create your account, log in, and step into the realm. Your game
        account is your identity here — one name for world and web alike.
      </p>
      <div v-if="account" class="hero-ctas">
        <span class="text-mist">
          Welcome back, {{ account.username }} — the realm is waiting.
        </span>
      </div>
      <div v-else class="hero-ctas">
        <NuxtLink to="/register" class="btn">Create account</NuxtLink>
        <NuxtLink to="/login" class="btn btn--ghost">Log in</NuxtLink>
      </div>
    </section>

    <ServerStatus />

    <section class="features">
      <div class="feature">
        <h3>One account</h3>
        <p>
          The name you register here is the name you log into the game with.
          No second password, no separate profile.
        </p>
      </div>
      <div class="feature">
        <h3>Sealed sessions</h3>
        <p>
          Login verifies your SRP6 credentials against the realm database and
          seals a signed cookie — the web layer never stores your password.
        </p>
      </div>
      <div class="feature">
        <h3>Live realm status</h3>
        <p>
          The banner above reads the realm's own heartbeat: online flag, fresh
          uptime row, and souls currently in game.
        </p>
      </div>
    </section>
  </div>
</template>
