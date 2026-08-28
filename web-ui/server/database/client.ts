// Nitro-coupled DB access: lazily-built mysql2 pools wrapped in Drizzle.
//
// One pool per database (realmd / characters), created on first use and
// cached on globalThis so dev HMR doesn't leak connections. Config errors
// surface here as CmangosConfigError at first DB-touching request — the
// health endpoint and static pages work even with no DB configured.

import { drizzle, type MySql2Database } from 'drizzle-orm/mysql2'
import mysql from 'mysql2/promise'
import type { H3Event } from 'h3'
import * as schema from './schema'
import {
  resolveCmangosConfig,
  type ResolvedCmangosConfig,
} from './config'

type Schema = typeof schema

interface DbCache {
  config?: ResolvedCmangosConfig
  realmd?: MySql2Database<Schema>
  characters?: MySql2Database<Schema>
}

const globalKey = '__cmangos_webui_db__'
const cache: DbCache = (globalThis as Record<string, unknown>)[
  globalKey
] as DbCache ?? ((globalThis as Record<string, unknown>)[globalKey] = {})

export function getCmangosConfig(event?: H3Event): ResolvedCmangosConfig {
  if (!cache.config) {
    const runtime = useRuntimeConfig(event)
    cache.config = resolveCmangosConfig(runtime.cmangos)
  }
  return cache.config
}

function createDb(conn: {
  host: string
  port: number
  user: string
  password: string
  database: string
}): MySql2Database<Schema> {
  const pool = mysql.createPool({
    ...conn,
    connectionLimit: 5,
    waitForConnections: true,
    enableKeepAlive: true,
  })
  return drizzle(pool, { schema, mode: 'default' })
}

export function getRealmdDb(event?: H3Event): MySql2Database<Schema> {
  if (!cache.realmd) cache.realmd = createDb(getCmangosConfig(event).realmd)
  return cache.realmd
}

export function getCharactersDb(event?: H3Event): MySql2Database<Schema> {
  if (!cache.characters)
    cache.characters = createDb(getCmangosConfig(event).characters)
  return cache.characters
}
