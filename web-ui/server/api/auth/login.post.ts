// POST /api/auth/login — verify credentials against realmd.account and open
// the sealed-cookie session. Recomputes the SRP6 verifier from the submitted
// password and compares with the stored v (see server/utils/auth.ts).

import { eq } from 'drizzle-orm'
import { account } from '../../database/schema'
import { getRealmdDb, getCmangosConfig } from '../../database/client'
import { CmangosConfigError } from '../../database/config'
import { getAuthAdapter } from '../../utils/auth'

export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => null)
  const username =
    typeof body?.username === 'string' ? body.username.trim().toUpperCase() : ''
  const password = typeof body?.password === 'string' ? body.password : ''

  if (!username || !password) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Username and password are required.',
    })
  }

  let db, config
  try {
    db = getRealmdDb(event)
    config = getCmangosConfig(event)
  } catch (e) {
    if (e instanceof CmangosConfigError) {
      throw createError({ statusCode: 500, statusMessage: e.message })
    }
    throw e
  }

  const rows = await db
    .select({
      id: account.id,
      username: account.username,
      v: account.v,
      s: account.s,
      locked: account.locked,
    })
    .from(account)
    .where(eq(account.username, username))
    .limit(1)

  const row = rows[0]
  const adapter = getAuthAdapter(config.core)

  const valid =
    row &&
    (await adapter.verifyCredentials(
      username,
      password,
      row.s ?? '',
      row.v ?? ''
    ))

  // Uniform failure — never reveal whether the username exists.
  if (!valid) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid username or password.',
    })
  }

  if (row.locked !== 0) {
    throw createError({
      statusCode: 403,
      statusMessage: 'This account is locked.',
    })
  }

  const session = await useAuthSession(event)
  await session.update({ accountId: row.id, username: row.username })

  return { id: row.id, username: row.username }
})
