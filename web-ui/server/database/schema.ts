// Drizzle descriptors for the CMaNGOS-owned tables the web UI touches.
//
// DESCRIPTORS ONLY — no migrations, ever (PLAN.md, decided): the schema is
// created and versioned by CMaNGOS itself. These mirror the upstream DDL so
// queries type-check; they must never be used to generate DDL.
//
// Source (verified 2026-08-26, byte-identical on classic/tbc/wotlk master):
// - sql/base/realmd.sql      → account, realmlist, uptime
// - sql/base/characters.sql  → characters

import { sql } from 'drizzle-orm'
import {
  bigint,
  char,
  datetime,
  float,
  index,
  int,
  longtext,
  mediumint,
  mysqlTable,
  primaryKey,
  smallint,
  text,
  tinyint,
  uniqueIndex,
  varchar,
} from 'drizzle-orm/mysql-core'

// ---------------------------------------------------------------------------
// realmd.account — the game's own account is the identity (PLAN.md).
// v/s hold the SRP6a verifier/salt as big-endian uppercase hex (BN_bn2hex),
// see server/utils/srp6.ts.
// ---------------------------------------------------------------------------
export const account = mysqlTable(
  'account',
  {
    id: int('id', { unsigned: true }).autoincrement().primaryKey(),
    username: varchar('username', { length: 32 }).notNull().default(''),
    gmlevel: tinyint('gmlevel', { unsigned: true }).notNull().default(0),
    sessionkey: longtext('sessionkey'),
    v: longtext('v'),
    s: longtext('s'),
    email: text('email'),
    // DB-owned default (DDL: DEFAULT NOW(), verified 2026-08-28). Declared
    // so the Drizzle insert type treats the column as optional — the
    // descriptor only mirrors the DDL; the web UI never writes it and no
    // DDL is ever generated from this file.
    joindate: datetime('joindate', { mode: 'string' })
      .notNull()
      .default(sql`NOW()`),
    lockedIp: varchar('lockedIp', { length: 30 }).notNull().default('0.0.0.0'),
    failedLogins: int('failed_logins', { unsigned: true }).notNull().default(0),
    locked: tinyint('locked', { unsigned: true }).notNull().default(0),
    lastModule: char('last_module', { length: 32 }).default(''),
    moduleDay: mediumint('module_day', { unsigned: true }).notNull().default(0),
    activeRealmId: int('active_realm_id', { unsigned: true })
      .notNull()
      .default(0),
    expansion: tinyint('expansion', { unsigned: true }).notNull().default(0),
    // Unix-seconds columns; safely inside Number's safe-integer range.
    mutetime: bigint('mutetime', { mode: 'number', unsigned: true })
      .notNull()
      .default(0),
    locale: varchar('locale', { length: 4 }).notNull().default(''),
    os: varchar('os', { length: 4 }).notNull().default('0'),
    platform: varchar('platform', { length: 4 }).notNull().default('0'),
    token: text('token'),
    flags: int('flags', { unsigned: true }).notNull().default(0),
  },
  (t) => [
    uniqueIndex('idx_username').on(t.username),
    index('idx_gmlevel').on(t.gmlevel),
  ]
)

// ---------------------------------------------------------------------------
// realmd.realmlist — realmflags bit 0x2 = offline (set by mangosd on
// graceful shutdown; a crashed core can leave it cleared — hence the uptime
// freshness check in /api/server/status).
// ---------------------------------------------------------------------------
export const realmlist = mysqlTable('realmlist', {
  id: int('id', { unsigned: true }).autoincrement().primaryKey(),
  name: varchar('name', { length: 32 }).notNull().default(''),
  realmflags: tinyint('realmflags', { unsigned: true }).notNull().default(2),
  population: float('population', { unsigned: true }).notNull().default(0),
})

// ---------------------------------------------------------------------------
// realmd.uptime — mangosd refreshes the row for (realmid, starttime) every
// UpdateUptimeInterval minutes (default 10 — src/game/World/World.cpp).
// starttime/uptime are unix seconds / elapsed seconds.
// ---------------------------------------------------------------------------
export const uptime = mysqlTable(
  'uptime',
  {
    realmid: int('realmid', { unsigned: true }).notNull(),
    starttime: bigint('starttime', { mode: 'number', unsigned: true })
      .notNull()
      .default(0),
    uptime: bigint('uptime', { mode: 'number', unsigned: true })
      .notNull()
      .default(0),
    maxplayers: smallint('maxplayers', { unsigned: true }).notNull().default(0),
  },
  (t) => [primaryKey({ columns: [t.realmid, t.starttime] })]
)

// ---------------------------------------------------------------------------
// <core>characters.characters — declared minimally (only what v1 reads).
// ---------------------------------------------------------------------------
export const characters = mysqlTable('characters', {
  guid: int('guid', { unsigned: true }).primaryKey(),
  account: int('account', { unsigned: true }).notNull().default(0),
  online: tinyint('online', { unsigned: true }).notNull().default(0),
})
