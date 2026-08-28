<script setup lang="ts">
useHead({ title: 'Create account' })

// Light client-side checks only — the server validates authoritatively and
// returns per-field errors (400 data.errors), which always win over these.
const username = ref('')
const email = ref('')
const password = ref('')
const confirm = ref('')
const pending = ref(false)
const banner = ref<string | null>(null)
const fieldErrors = ref<Record<string, string>>({})
const created = ref<string | null>(null)

function localErrors(): Record<string, string> {
  const e: Record<string, string> = {}
  if (!username.value.trim()) e.username = 'Username is required.'
  if (!email.value.trim()) e.email = 'Email is required.'
  if (password.value.length < 4 || password.value.length > 16)
    e.password = 'Password must be 4-16 characters.'
  if (password.value !== confirm.value)
    e.confirm = 'Passwords do not match.'
  return e
}

async function onSubmit() {
  if (pending.value) return
  banner.value = null
  fieldErrors.value = localErrors()
  if (Object.keys(fieldErrors.value).length > 0) return

  pending.value = true
  try {
    const res = await $fetch<{ username: string }>('/api/auth/register', {
      method: 'POST',
      body: {
        username: username.value,
        email: email.value,
        password: password.value,
      },
    })
    created.value = res.username
  } catch (err) {
    const fromServer = apiFieldErrors(err)
    if (Object.keys(fromServer).length > 0) {
      fieldErrors.value = fromServer
      return
    }
    const code = (err as { statusCode?: number; data?: { statusCode?: number } })
      ?.statusCode ?? (err as { data?: { statusCode?: number } })?.data?.statusCode
    if (code === 409) {
      fieldErrors.value = { username: 'Username is already taken.' }
    } else {
      banner.value = apiErrorMessage(err, 'Registration failed. Try again.')
    }
  } finally {
    pending.value = false
  }
}
</script>

<template>
  <div class="auth-wrap">
    <div v-if="created" class="panel">
      <h1 class="panel-title">Account forged.</h1>
      <p>
        <strong>{{ created }}</strong> now has a place in the realm. Log in
        with the same name and password you use for the game.
      </p>
      <NuxtLink to="/login" class="btn">Continue to login</NuxtLink>
    </div>

    <div v-else class="panel">
      <h1 class="panel-title">Create account</h1>
      <p class="text-mist">
        One registration, two worlds: this account works on this site and in
        the game client alike.
      </p>

      <p v-if="banner" class="form-banner" role="alert">{{ banner }}</p>

      <form @submit.prevent="onSubmit">
        <div class="field" :class="{ 'field--invalid': fieldErrors.username }">
          <label for="reg-username">Username</label>
          <input
            id="reg-username"
            v-model="username"
            type="text"
            required
            autocomplete="username"
            maxlength="16"
          />
          <p v-if="fieldErrors.username" class="field__error">
            {{ fieldErrors.username }}
          </p>
          <p v-else class="field__hint">
            2-16 characters: letters, digits, dash, underscore.
          </p>
        </div>

        <div class="field" :class="{ 'field--invalid': fieldErrors.email }">
          <label for="reg-email">Email</label>
          <input
            id="reg-email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
          />
          <p v-if="fieldErrors.email" class="field__error">
            {{ fieldErrors.email }}
          </p>
        </div>

        <div class="field" :class="{ 'field--invalid': fieldErrors.password }">
          <label for="reg-password">Password</label>
          <input
            id="reg-password"
            v-model="password"
            type="password"
            required
            autocomplete="new-password"
            maxlength="16"
          />
          <p v-if="fieldErrors.password" class="field__error">
            {{ fieldErrors.password }}
          </p>
          <p v-else class="field__hint">4-16 characters.</p>
        </div>

        <div class="field" :class="{ 'field--invalid': fieldErrors.confirm }">
          <label for="reg-confirm">Confirm password</label>
          <input
            id="reg-confirm"
            v-model="confirm"
            type="password"
            required
            autocomplete="new-password"
            maxlength="16"
          />
          <p v-if="fieldErrors.confirm" class="field__error">
            {{ fieldErrors.confirm }}
          </p>
        </div>

        <button type="submit" class="btn" :disabled="pending">
          {{ pending ? 'Forging…' : 'Forge account' }}
        </button>
      </form>
    </div>

    <p class="auth-foot">
      Already sworn in? <NuxtLink to="/login">Log in.</NuxtLink>
    </p>
  </div>
</template>
