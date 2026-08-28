import { describe, expect, test } from 'bun:test'
import { validateRegistration } from '../server/utils/validation'

const good = { username: 'Player_One', password: 'secret1', email: 'a@b.cd' }

describe('validateRegistration', () => {
  test('accepts a valid registration and normalizes', () => {
    const res = validateRegistration(good)
    expect(res.ok).toBe(true)
    if (res.ok) {
      expect(res.data.username).toBe('PLAYER_ONE') // stored uppercase
      expect(res.data.email).toBe('a@b.cd')
      expect(res.data.password).toBe('secret1')
    }
  })

  test.each([
    'A', // too short
    'ABCDEFGHIJKLMNOPQ', // 17 chars
    'HAS SPACE',
    'BAD!CHAR',
    'ACCENTÉ',
    '',
  ])('rejects username %j', (username: string) => {
    const res = validateRegistration({ ...good, username })
    expect(res.ok).toBe(false)
    if (!res.ok) expect(res.errors.username).toBeTruthy()
  })

  test.each(['AB', 'PLAYER-2', '_UNDERSCORE', '9LIVES'])(
    'accepts username %j',
    (username: string) => {
      expect(validateRegistration({ ...good, username }).ok).toBe(true)
    }
  )

  test.each(['abc', 'a'.repeat(17), ''])('rejects password %j', (password: string) => {
    const res = validateRegistration({ ...good, password })
    expect(res.ok).toBe(false)
    if (!res.ok) expect(res.errors.password).toBeTruthy()
  })

  test.each(['abcd', 'x'.repeat(16)])('accepts password %j', (password: string) => {
    expect(validateRegistration({ ...good, password }).ok).toBe(true)
  })

  test.each(['plain', 'a@', '@b.cd', 'a b@c.d', ''])(
    'rejects email %j',
    (email: string) => {
      const res = validateRegistration({ ...good, email })
      expect(res.ok).toBe(false)
      if (!res.ok) expect(res.errors.email).toBeTruthy()
    }
  )

  test('trims email whitespace before validating', () => {
    const res = validateRegistration({ ...good, email: '  a@b.cd  ' })
    expect(res.ok).toBe(true)
    if (res.ok) expect(res.data.email).toBe('a@b.cd')
  })

  test('non-string fields are rejected, not crashed on', () => {
    const res = validateRegistration({
      username: 42,
      password: null,
      email: undefined,
    })
    expect(res.ok).toBe(false)
    if (!res.ok) {
      expect(res.errors.username).toBeTruthy()
      expect(res.errors.password).toBeTruthy()
      expect(res.errors.email).toBeTruthy()
    }
  })

  test('reports all field errors at once', () => {
    const res = validateRegistration({ username: '!', password: 'x', email: 'y' })
    expect(res.ok).toBe(false)
    if (!res.ok) expect(Object.keys(res.errors).sort()).toEqual(['email', 'password', 'username'])
  })
})
