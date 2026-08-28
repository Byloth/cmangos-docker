// POST /api/auth/register — create a game account in realmd.account.
//
// The game's own account IS the identity (PLAN.md): this endpoint writes
// exactly the row a retail client then logs in with. Validation rules and
// the SRP6 credential material are unit-tested; the Drizzle round-trip
// against live MariaDB is untestable on the dev box (no docker/mysql) and
// must be verified on the homelab — tracked in PLAN.md / PR #44.

import { eq } from 'drizzle-orm'
import { account } from '../../database/schema'
import { getRealmdDb, getCmangosConfig } from '../../database/client'
import {
  CmangosConfigError,
  CORE_ACCOUNT_EXPANSION,
} from '../../database/config'
import { getAuthAdapter } from '../../utils/auth'
import { validateRegistration } from '../../utils/validation'

export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => null)
  const result = validateRegistration(body ?? {})

  if (!result.ok) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid registration data.',
      data: { errors: result.errors },
    })
  }
  const { username, password, email } = result.data

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

  const adapter = getAuthAdapter(config.core)

  const existing = await db
    .select({ id: account.id })
    .from(account)
    .where(eq(account.username, username))
    .limit(1)

  if (existing.length > 0) {
    throw createError({
      statusCode: 409,
      statusMessage: 'Username is already taken.',
    })
  }

  const { v, s } = await adapter.createCredentials(username, password)

  const inserted = await db
    .insert(account)
    .values({
      username,
      v,
      s,
      email,
      expansion: CORE_ACCOUNT_EXPANSION[config.core],
    })
    .$returningId()

  const id = inserted[0]?.id
  if (id === undefined) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Account creation failed unexpectedly.',
    })
  }

  setResponseStatus(event, 201)
  return {
    id,
    username,
    email,
  }
})
