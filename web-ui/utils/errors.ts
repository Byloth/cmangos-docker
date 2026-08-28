// Shared client-side helpers (auto-imported by Nuxt from utils/).

/** Extract a human-readable message from an h3/$fetch error. */
export function apiErrorMessage(err: unknown, fallback: string): string {
  const e = err as {
    data?: { statusMessage?: string }
    statusMessage?: string
  } | null
  return e?.data?.statusMessage || e?.statusMessage || fallback
}

/** Per-field errors thrown by POST /api/auth/register as data.errors. */
export function apiFieldErrors(err: unknown): Record<string, string> {
  const e = err as { data?: { errors?: Record<string, string> } } | null
  return e?.data?.errors ?? {}
}
