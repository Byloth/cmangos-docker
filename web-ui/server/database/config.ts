// Resolution + validation of the CMaNGOS runtime config.
//
// Pure and framework-free on purpose: unit tests import this directly, and
// the nitro-coupled client (client.ts) is the only caller that feeds it the
// live runtimeConfig. Every validation error names the exact NUXT_* env var
// an operator must set.

export type CmangosCore = 'classic' | 'tbc' | 'wotlk'

export const CMANGOS_CORES: readonly CmangosCore[] = [
  'classic',
  'tbc',
  'wotlk',
]

// account.expansion value stamped at registration: the max expansion the
// configured core supports (classic 0, tbc 1, wotlk 2). Server-derived,
// never taken from the client.
export const CORE_ACCOUNT_EXPANSION: Record<CmangosCore, number> = {
  classic: 0,
  tbc: 1,
  wotlk: 2,
}

export interface CmangosRuntimeInput {
  core?: string
  db?: {
    host?: string
    port?: number | string
    user?: string
    password?: string
    realmdName?: string
    charactersName?: string
  }
}

export interface CmangosDbConnection {
  host: string
  port: number
  user: string
  password: string
  database: string
}

export interface ResolvedCmangosConfig {
  core: CmangosCore
  realmd: CmangosDbConnection
  characters: CmangosDbConnection
}

export class CmangosConfigError extends Error {
  constructor(public readonly problems: string[]) {
    super(
      'Invalid CMaNGOS web UI configuration:\n' +
        problems.map((p) => `  - ${p}`).join('\n')
    )
    this.name = 'CmangosConfigError'
  }
}

export function resolveCmangosConfig(
  input: CmangosRuntimeInput
): ResolvedCmangosConfig {
  const problems: string[] = []

  const core = (input.core ?? '').trim().toLowerCase()
  if (!CMANGOS_CORES.includes(core as CmangosCore)) {
    problems.push(
      `NUXT_CMANGOS_CORE must be one of ${CMANGOS_CORES.join(' | ')} (got "${
        input.core ?? ''
      }")`
    )
  }

  const host = (input.db?.host ?? '').trim()
  if (!host) problems.push('NUXT_CMANGOS_DB_HOST is required')

  const port = Number(input.db?.port ?? 3306)
  if (!Number.isInteger(port) || port <= 0 || port > 65535) {
    problems.push(
      `NUXT_CMANGOS_DB_PORT must be an integer 1-65535 (got "${input.db?.port}")`
    )
  }

  const user = input.db?.user ?? ''
  if (!user) problems.push('NUXT_CMANGOS_DB_USER is required')

  const password = input.db?.password ?? ''
  if (!password) problems.push('NUXT_CMANGOS_DB_PASSWORD is required')

  if (problems.length > 0) throw new CmangosConfigError(problems)

  // From here core/host/port are valid.
  const validCore = core as CmangosCore
  const base = { host, port, user, password }

  return {
    core: validCore,
    realmd: {
      ...base,
      database: input.db?.realmdName?.trim() || `${validCore}realmd`,
    },
    characters: {
      ...base,
      database: input.db?.charactersName?.trim() || `${validCore}characters`,
    },
  }
}
