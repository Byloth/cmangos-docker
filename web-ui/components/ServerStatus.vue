<script setup lang="ts">
// Live realm status widget — polls GET /api/server/status every 30s.
// Client-only by design: SSR renders the "consulting" placeholder, the first
// fetch happens onMounted. On the dev box (no DB) the API 500s and the widget
// shows its unavailable state — that path is intentional and visible.

interface ServerStatusResponse {
  realm: {
    name: string
    online: boolean
    onlineCount: number
    maxPlayers: number
  }
  details: {
    flaggedOffline: boolean
    staleUptime: boolean
  }
}

const status = ref<ServerStatusResponse | null>(null)
const unavailable = ref<string | null>(null)

async function load() {
  try {
    status.value = await $fetch<ServerStatusResponse>('/api/server/status')
    unavailable.value = null
  } catch (err) {
    status.value = null
    unavailable.value = apiErrorMessage(err, 'Status unavailable')
  }
}

let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  load()
  timer = setInterval(load, 30_000)
})
onBeforeUnmount(() => clearInterval(timer))

const state = computed<'loading' | 'online' | 'offline' | 'unknown'>(() => {
  if (status.value) return status.value.realm.online ? 'online' : 'offline'
  if (unavailable.value) return 'unknown'
  return 'loading'
})

const offlineReason = computed(() => {
  const d = status.value?.details
  if (!d) return ''
  if (d.flaggedOffline) return 'realm flagged offline (shutdown or maintenance)'
  if (d.staleUptime) return 'no heartbeat from the world server'
  return ''
})
</script>

<template>
  <div class="panel status-card" role="status" aria-live="polite">
    <span
      class="status-dot"
      :class="{
        'status-dot--online': state === 'online',
        'status-dot--offline': state === 'offline',
        'status-dot--unknown': state === 'unknown' || state === 'loading',
      }"
    />

    <div>
      <div class="status-card__name">
        {{ status?.realm.name ?? 'Realm status' }}
      </div>
      <p v-if="state === 'loading'" class="status-card__line">
        Consulting the realm…
      </p>
      <p v-else-if="state === 'unknown'" class="status-card__line">
        Status unavailable — {{ unavailable }}
      </p>
      <p v-else-if="state === 'offline'" class="status-card__line">
        Offline<template v-if="offlineReason"> — {{ offlineReason }}</template>
      </p>
      <p v-else class="status-card__line">The realm is open.</p>
    </div>

    <div v-if="state === 'online'" class="status-card__count">
      <strong>{{ status!.realm.onlineCount }}</strong>
      <span>
        {{ status!.realm.onlineCount === 1 ? 'soul' : 'souls' }} in game
      </span>
    </div>
  </div>
</template>
