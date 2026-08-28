import { describe, it, expect } from 'bun:test'
import { generateSalt, generateVerifier, N, g } from '../server/utils/srp6'

const SALT = 'AABBCCDD11223344556677889900AABBCCDD11223344556677889900AABBCCDD'

describe('srp6', () => {
  it('N and g are the expected CMaNGOS parameters', () => {
    expect(N.toString(16).toUpperCase()).toBe(
      '894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7'
    )
    expect(g).toBe(7n)
  })

  it('generateSalt returns 64 uppercase hex chars (32 bytes)', () => {
    const salt = generateSalt()
    expect(salt).toMatch(/^[0-9A-F]{64}$/)
  })

  it('generateVerifier is deterministic', async () => {
    const v1 = await generateVerifier('testuser', 'testpass', SALT)
    const v2 = await generateVerifier('testuser', 'testpass', SALT)
    expect(v1).toBe(v2)
    expect(v1).toMatch(/^[0-9A-F]+$/)
  })

  it('generateVerifier respects CMaNGOS case rules', async () => {
    const vLower = await generateVerifier('testuser', 'testpass', SALT)
    const vUpper = await generateVerifier('TESTUSER', 'TESTPASS', SALT)
    expect(vLower).toBe(vUpper)
  })

  it('accepts lowercase salt hex (SetHexStr/BN_hex2bn semantics)', async () => {
    const vUpper = await generateVerifier('ADMIN', 'ADMIN', SALT)
    const vLower = await generateVerifier('ADMIN', 'ADMIN', SALT.toLowerCase())
    expect(vLower).toBe(vUpper)
  })

  it('serialize/parse round-trip: bigint value survives DB hex storage', async () => {
    // BN_hex2bn(AsHexStr(v)) === v — the property that makes realmd able
    // to use what we INSERT.
    const v = await generateVerifier('ADMIN', 'ADMIN', SALT)
    expect(BigInt('0x' + v).toString(16).toUpperCase()).toBe(v)
  })

  it('known vector: ADMIN/ADMIN with fixed salt (Python-computed)', async () => {
    // Computed with hashlib/pow (big-endian serialization per AsHexStr):
    //   h1 = sha1(b"ADMIN:ADMIN")
    //   x  = sha1(bytes.fromhex(SALT)[::-1] + h1[::-1]), read big-endian
    //   v  = pow(7, x, N) → hex, uppercase, unpadded
    const v = await generateVerifier('ADMIN', 'ADMIN', SALT)
    expect(v).toBe('28AE3C33E905D329A887D26E844AFDE10687C9E283940127D3E1A97A3DD157BB')
  })
})
