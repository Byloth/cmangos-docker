import { describe, expect, test } from 'bun:test'
import {
  CmangosConfigError,
  CORE_ACCOUNT_EXPANSION,
  resolveCmangosConfig,
} from '../server/database/config'

const valid = {
  core: 'tbc',
  db: { host: 'db', port: 3306, user: 'mangos', password: 'secret' },
}

describe('resolveCmangosConfig', () => {
  test('derives database names from the core', () => {
    const cfg = resolveCmangosConfig(valid)
    expect(cfg.core).toBe('tbc')
    expect(cfg.realmd.database).toBe('tbcrealmd')
    expect(cfg.characters.database).toBe('tbccharacters')
    expect(cfg.realmd.host).toBe('db')
    expect(cfg.realmd.port).toBe(3306)
    expect(cfg.characters.user).toBe('mangos')
  })

  test.each(['classic', 'tbc', 'wotlk'] as const)('accepts core %s', (core: string) => {
    const cfg = resolveCmangosConfig({ ...valid, core })
    expect(cfg.realmd.database).toBe(`${core}realmd`)
  })

  test('normalizes core casing', () => {
    expect(resolveCmangosConfig({ ...valid, core: ' TBC ' }).core).toBe('tbc')
  })

  test('honours explicit database name overrides', () => {
    const cfg = resolveCmangosConfig({
      ...valid,
      db: { ...valid.db, realmdName: 'custom_auth', charactersName: 'chars1' },
    })
    expect(cfg.realmd.database).toBe('custom_auth')
    expect(cfg.characters.database).toBe('chars1')
  })

  test('accepts port as string', () => {
    expect(
      resolveCmangosConfig({ ...valid, db: { ...valid.db, port: '3406' } })
        .realmd.port
    ).toBe(3406)
  })

  test('collects every problem in one error, naming the NUXT_ vars', () => {
    try {
      resolveCmangosConfig({ core: 'vanilla', db: {} })
      expect.unreachable('should have thrown')
    } catch (e) {
      expect(e).toBeInstanceOf(CmangosConfigError)
      const msg = (e as Error).message
      expect(msg).toContain('NUXT_CMANGOS_CORE')
      expect(msg).toContain('NUXT_CMANGOS_DB_HOST')
      expect(msg).toContain('NUXT_CMANGOS_DB_USER')
      expect(msg).toContain('NUXT_CMANGOS_DB_PASSWORD')
    }
  })

  test('rejects a bad port', () => {
    expect(() =>
      resolveCmangosConfig({ ...valid, db: { ...valid.db, port: 'abc' } })
    ).toThrow(CmangosConfigError)
  })

  test('expansion mapping matches classic/tbc/wotlk = 0/1/2', () => {
    expect(CORE_ACCOUNT_EXPANSION).toEqual({ classic: 0, tbc: 1, wotlk: 2 })
  })
})
