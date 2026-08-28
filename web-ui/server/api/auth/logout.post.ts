// POST /api/auth/logout — clear the sealed-cookie session.

export default defineEventHandler(async (event) => {
  const session = await useAuthSession(event)
  await session.clear()
  return { ok: true }
})
