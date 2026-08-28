// GET /api/auth/me — the current session's identity, or null when not
// logged in. Deliberately returns the session payload only (no DB read):
// the session is the sealed source of truth for who is logged in.

export default defineEventHandler(async (event) => {
  const data = await getAuthSessionData(event)
  if (!data) return { account: null }
  return {
    account: {
      id: data.accountId,
      username: data.username,
    },
  }
})
