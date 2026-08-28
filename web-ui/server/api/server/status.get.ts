// GET /api/server/status — realm online status and player count.
//
// Logic:
// 1. Read `realmlist` for the primary realm's `realmflags`.
//    Bit 0x2 = offline (set by mangosd on graceful shutdown).
// 2. Read `uptime` for the most recent entry for that realm.
//    If (currentTime - starttime) > (UpdateUptimeInterval * 60) + buffer,
//    the realm is effectively offline (crashed or not started).
// 3. Read `characters` for the count of records where `online = 1`.
//
// Runtime behavior against real MariaDB is UNTESTED (no docker/mysql on dev box).

import { eq, desc, sql } from 'drizzle-orm'
import { realmlist, uptime, characters } from '../../database/schema'
import { getRealmdDb, getCharactersDb, getCmangosConfig } from '../../database/client'
import { CmangosConfigError } from '../../database/config'

const UPTIME_UPDATE_INTERVAL_MINUTES = 10
const STALE_BUFFER_SECONDS = 60

export default defineEventHandler(async (event) => {
  let realmdDb, charDb, config
  try {
    realmdDb = getRealmdDb(event)
    charDb = getCharactersDb(event)
    config = getCmangosConfig(event)
  } catch (e) {
    if (e instanceof CmangosConfigError) {
      throw createError({ statusCode: 500, statusMessage: e.message })
    }
    throw e
  }

  // 1. Realm flags from realmlist.
  const realms = await realmdDb
    .select({
      id: realmlist.id,
      name: realmlist.name,
      flags: realmlist.realmflags,
    })
    .from(realmlist)
    .limit(1)

  const realm = realms[0]
  if (!realm) {
    throw createError({
      statusCode: 404,
      statusMessage: 'No realms configured in the database.',
    })
  }

  const isFlaggedOffline = (realm.flags & 0x2) !== 0

  // 2. Uptime freshness.
  const latestUptime = await realmdDb
    .select({
      starttime: uptime.starttime,
      maxplayers: uptime.maxplayers,
    })
    .from(uptime)
    .where(eq(uptime.realmid, realm.id))
    .orderBy(desc(uptime.starttime))
    .limit(1)

  let isStale = true
  let maxPlayers = 0
  const uptimeRow = latestUptime[0]
  if (uptimeRow) {
    const { starttime, maxplayers } = uptimeRow
    const now = Math.floor(Date.now() / 1000)
    const age = now - starttime
    const threshold = UPTIME_UPDATE_INTERVAL_MINUTES * 60 + STALE_BUFFER_SECONDS
    isStale = age > threshold
    maxPlayers = maxplayers
  }

  // 3. Online count.
  const onlineCountRes = await charDb
    .select({ count: sql`count(*)` })
    .from(characters)

  const onlineCount = Number(onlineCountRes[0]?.count ?? 0)
  const isOnline = !isFlaggedOffline && !isStale

  return {
    realm: {
      name: realm.name,
      online: isOnline,
      onlineCount,
      maxPlayers,
    },
    details: {
      flaggedOffline: isFlaggedOffline,
      staleUptime: isStale,
    },
  }
})
