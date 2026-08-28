// Registration input validation — pure, framework-free, unit-tested.
// Rules follow the WoWSimpleRegistration user-side reference (PLAN.md):
// username [0-9A-Z-_]+ 2–16, password 4–16, email required + validated.
//
// Usernames are stored UPPERCASE (CMaNGOS convention: the core uppercases
// account names), so validation happens against the uppercased form.

export const USERNAME_PATTERN = /^[0-9A-Z_-]{2,16}$/
export const PASSWORD_MIN = 4
export const PASSWORD_MAX = 16
// Deliberately simple: real deliverability is checked by sending mail, and
// v1 has no mailer. This catches typos, not fraud.
export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
export const EMAIL_MAX = 254

export interface RegistrationInput {
  username?: unknown
  password?: unknown
  email?: unknown
}

export interface ValidatedRegistration {
  /** uppercased, as stored in realmd.account */
  username: string
  password: string
  /** trimmed, case preserved */
  email: string
}

export type RegistrationErrors = Partial<
  Record<'username' | 'password' | 'email', string>
>

export type RegistrationResult =
  | { ok: true; data: ValidatedRegistration }
  | { ok: false; errors: RegistrationErrors }

export function validateRegistration(
  input: RegistrationInput
): RegistrationResult {
  const errors: RegistrationErrors = {}

  const username =
    typeof input.username === 'string' ? input.username.trim().toUpperCase() : ''
  if (!username) {
    errors.username = 'Username is required.'
  } else if (!USERNAME_PATTERN.test(username)) {
    errors.username =
      'Username must be 2-16 characters: letters, digits, dash, underscore.'
  }

  const password = typeof input.password === 'string' ? input.password : ''
  if (!password) {
    errors.password = 'Password is required.'
  } else if (
    password.length < PASSWORD_MIN ||
    password.length > PASSWORD_MAX
  ) {
    errors.password = `Password must be ${PASSWORD_MIN}-${PASSWORD_MAX} characters.`
  }

  const email = typeof input.email === 'string' ? input.email.trim() : ''
  if (!email) {
    errors.email = 'Email is required.'
  } else if (email.length > EMAIL_MAX || !EMAIL_PATTERN.test(email)) {
    errors.email = 'Enter a valid email address.'
  }

  if (Object.keys(errors).length > 0) return { ok: false, errors }
  return { ok: true, data: { username, password, email } }
}
