// Auth adapter seam (PLAN.md: "Core adapter per expansion").
//
// Verified 2026-08-24/26 against cmangos master: ALL THREE current cores
// (classic/tbc/wotlk) authenticate with SRP6a — realmd's AuthSocket queries
// v,s and SRP6.cpp is identical across them — so one adapter serves every
// core. Legacy deployments carrying pre-SRP6 sha_pass_hash accounts are NOT
// supported; getAuthAdapter is the seam where such an adapter would slot in
// without the rest of the code branching on expansion.

import { generateSalt, generateVerifier } from './srp6'
import type { CmangosCore } from '../database/config'

export interface AccountCredentials {
  /** verifier, big-endian uppercase hex (as CMaNGOS stores it) */
  v: string
  /** salt, big-endian uppercase hex (as CMaNGOS stores it) */
  s: string
}

export interface AuthAdapter {
  readonly name: string
  createCredentials(
    username: string,
    password: string
  ): Promise<AccountCredentials>
  verifyCredentials(
    username: string,
    password: string,
    storedS: string,
    storedV: string
  ): Promise<boolean>
}

const srp6Adapter: AuthAdapter = {
  name: 'srp6a',

  async createCredentials(username, password) {
    const s = generateSalt()
    const v = await generateVerifier(username, password, s)
    return { v, s }
  },

  async verifyCredentials(username, password, storedS, storedV) {
    // Accounts without SRP6 material (legacy or externally managed rows)
    // simply cannot authenticate through this adapter.
    if (!/^[0-9A-Fa-f]+$/.test(storedS) || !/^[0-9A-Fa-f]+$/.test(storedV)) {
      return false
    }
    const computed = await generateVerifier(username, password, storedS)
    // Compare as integers, not strings: BN_hex2bn accepts any case and
    // strips leading zeros, so realmd would too — match that tolerance.
    return BigInt('0x' + computed) === BigInt('0x' + storedV)
  },
}

export function getAuthAdapter(_core: CmangosCore): AuthAdapter {
  return srp6Adapter
}
