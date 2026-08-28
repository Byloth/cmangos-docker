// SRP6a salt/verifier generation for CMaNGOS realmd.account — all three cores
// (classic/tbc/wotlk share an identical SRP6 implementation since the wotlk
// realm-list rewrite; verified against cmangos master, 2026-08).
//
// Sources (CMaNGOS):
// - src/shared/Auth/SRP6.cpp  — CalculateVerifier
// - src/game/Accounts/AccountMgr.cpp — CreateAccount / CalculateShaPassHash
//
// Exact data flow in the core:
//   h1  = sha1(USERNAME:PASSWORD)                       (both uppercased)
//   I   = hex-encode(h1)                                (CalculateShaPassHash)
//   s   = 32 random bytes
//   x   = sha1(LE_bytes(s) || LE_bytes(h1))  read as big-endian integer
//   v   = g^x mod N                                     (N, g per RFC 5054)
//
// DB serialization (what realmd/account expect back):
//   s → AsHexStr() = BN_bn2hex: big-endian, UPPERCASE, unpadded
//   v → AsHexStr() = BN_bn2hex: big-endian, UPPERCASE, unpadded
// Both are parsed with SetHexStr → BN_hex2bn, so case/padding don't matter
// for round-trip — but we emit the exact form the core emits.
//
// Sanity check, from the protocol: realmd sends B = (k*v + g^b) mod N to the
// client. If v were stored little-endian, B would be garbage to a retail
// client. Big-endian storage is the only form that interoperates.

const N_HEX =
  '894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7'
const G_HEX = '07'

export const N = BigInt('0x' + N_HEX)
export const g = BigInt('0x' + G_HEX)

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2)
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16)
  }
  return bytes
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function reverseBytes(bytes: Uint8Array): Uint8Array {
  return new Uint8Array(bytes.slice().reverse())
}

async function sha1(data: Uint8Array): Promise<Uint8Array> {
  // Copy into a plain ArrayBuffer-backed view: TS's BufferSource type
  // rejects SharedArrayBuffer-backed views.
  const view = new Uint8Array(data)
  const buf = await crypto.subtle.digest('SHA-1', view)
  return new Uint8Array(buf)
}

function concatBytes(a: Uint8Array, b: Uint8Array): Uint8Array {
  const c = new Uint8Array(a.length + b.length)
  c.set(a, 0)
  c.set(b, a.length)
  return c
}

function stringToBytes(s: string): Uint8Array {
  return new TextEncoder().encode(s)
}

/**
 * Generate a random 32-byte salt, serialized as CMaNGOS stores it:
 * big-endian uppercase hex (BN_bn2hex of the random BigNumber).
 */
export function generateSalt(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32))
  return bytesToHex(bytes).toUpperCase()
}

/**
 * Compute the SRP6 verifier for CMaNGOS realmd.account.
 *
 * Returns the verifier serialized as CMaNGOS stores it: big-endian uppercase
 * hex, unpadded (BN_bn2hex of v). Length may be shorter than 64 chars when
 * the top bytes of v are zero — that is normal and matches the core.
 */
export async function generateVerifier(
  username: string,
  password: string,
  saltHex: string
): Promise<string> {
  const userUpper = username.toUpperCase()
  const passUpper = password.toUpperCase()

  const salt = hexToBytes(saltHex)

  const h1 = await sha1(stringToBytes(userUpper + ':' + passUpper))
  // CMaNGOS: sha.UpdateData(s.AsByteArray()); sha.UpdateData(mDigest);
  // where both AsByteArray() and mDigest are little-endian byte order.
  const xBytes = await sha1(concatBytes(reverseBytes(salt), reverseBytes(h1)))

  // x is then read with SetBinary → big-endian integer.
  const xInt = BigInt('0x' + bytesToHex(xBytes))
  const vInt = modPow(g, xInt, N)

  // AsHexStr → BN_bn2hex: big-endian, uppercase, unpadded.
  return vInt.toString(16).toUpperCase()
}

/**
 * Modular exponentiation: (base^exp) mod mod
 */
function modPow(base: bigint, exp: bigint, mod: bigint): bigint {
  let result = 1n
  let b = base % mod
  let e = exp
  while (e > 0n) {
    if (e & 1n) {
      result = (result * b) % mod
    }
    b = (b * b) % mod
    e = e >> 1n
  }
  return result
}
