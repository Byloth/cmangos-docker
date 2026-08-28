// Session plumbing — thin wrappers over h3's useSession so every endpoint
// shares one cookie config. The cookie is sealed (encrypted + signed) with
// NUXT_SESSION_PASSWORD and carries only the account id + username.
//
// Cookie attributes are NOT configurable here beyond maxAge/secure: the
// httpOnly + SameSite=Lax defaults are security posture, not preference.
// `secure` stays off by default because the docker stack is plain HTTP on
// a LAN (see .env.example).

import type { H3Event } from 'h3'

export interface SessionData {
  accountId: number
  username: string
}

const MIN_PASSWORD_LENGTH = 32

export function useAuthSession(event: H3Event) {
  const config = useRuntimeConfig(event)
  const password: string = config.session?.password ?? ''

  if (password.length < MIN_PASSWORD_LENGTH) {
    throw createError({
      statusCode: 500,
      statusMessage:
        'Server misconfiguration: NUXT_SESSION_PASSWORD must be at least 32 characters.',
    })
  }

  return useSession<SessionData>(event, {
    password,
    maxAge: Number(config.session?.maxAge ?? 60 * 60 * 24 * 7),
    name: 'cmangos-auth',
    cookie: {
      httpOnly: true,
      sameSite: 'lax',
      secure: config.session?.secureCookie === true,
      path: '/',
    },
  })
}

/** Read the current session data without creating a new session. */
export async function getAuthSessionData(
  event: H3Event
): Promise<SessionData | null> {
  const session = await useAuthSession(event)
  const data = session.data
  if (
    typeof data?.accountId !== 'number' ||
    typeof data?.username !== 'string'
  ) {
    return null
  }
  return { accountId: data.accountId, username: data.username }
}
