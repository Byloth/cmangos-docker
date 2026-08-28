// Session state for the web UI. The game account IS the identity (PLAN.md);
// /api/auth/me reads the sealed cookie only, no DB round-trip.

export interface AuthAccount {
  id: number
  username: string
}

export function useAuth() {
  const account = useState<AuthAccount | null>('auth:account', () => null)
  const loaded = useState<boolean>('auth:loaded', () => false)

  async function refresh() {
    try {
      const res = await $fetch<{ account: AuthAccount | null }>(
        '/api/auth/me',
        {
          // During SSR the incoming cookie must be forwarded explicitly.
          headers: import.meta.server
            ? useRequestHeaders(['cookie'])
            : undefined,
        }
      )
      account.value = res.account
    } catch {
      account.value = null
    } finally {
      loaded.value = true
    }
  }

  async function login(username: string, password: string) {
    await $fetch('/api/auth/login', {
      method: 'POST',
      body: { username, password },
    })
    await refresh()
  }

  async function logout() {
    try {
      await $fetch('/api/auth/logout', { method: 'POST' })
    } finally {
      account.value = null
    }
  }

  return { account, loaded, refresh, login, logout }
}
