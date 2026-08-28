import { describe, expect, test } from 'bun:test'
import { getAuthAdapter } from '../server/utils/auth'
import type { CmangosCore } from '../server/database/config'

const adapter = getAuthAdapter('tbc')

describe('auth adapter (srp6a, all cores)', () => {
  test.each(['classic', 'tbc', 'wotlk'] as const)(
    'core %s maps to the srp6a adapter',
    (core: CmangosCore) => {
      expect(getAuthAdapter(core).name).toBe('srp6a')
    }
  )

  test('created credentials verify against the same password', async () => {
    const { v, s } = await adapter.createCredentials('PLAYER', 'secret1')
    expect(v).toMatch(/^[0-9A-F]+$/)
    expect(s).toMatch(/^[0-9A-F]{64}$/)
    expect(await adapter.verifyCredentials('PLAYER', 'secret1', s, v)).toBe(
      true
    )
  })

  test('username case is irrelevant (core uppercases)', async () => {
    const { v, s } = await adapter.createCredentials('PLAYER', 'secret1')
    expect(await adapter.verifyCredentials('player', 'secret1', s, v)).toBe(
      true
    )
  })

  test('wrong password does not verify', async () => {
    const { v, s } = await adapter.createCredentials('PLAYER', 'secret1')
    expect(await adapter.verifyCredentials('PLAYER', 'secret2', s, v)).toBe(
      false
    )
  })

  test('stored verifier verifies regardless of case/padding (BN_hex2bn tolerance)', async () => {
    const { v, s } = await adapter.createCredentials('PLAYER', 'secret1')
    const lowerPadded = ('0000' + v.toLowerCase()).replace(/^0+(?=[0-9a-f]{4})/, '')
    expect(
      await adapter.verifyCredentials('PLAYER', 'secret1', s.toLowerCase(), lowerPadded)
    ).toBe(true)
  })

  test('rows without SRP6 material cannot authenticate', async () => {
    expect(await adapter.verifyCredentials('PLAYER', 'secret1', '', '')).toBe(
      false
    )
    expect(
      await adapter.verifyCredentials('PLAYER', 'secret1', 'zz', 'not-hex')
    ).toBe(false)
  })
})
