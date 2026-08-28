<script setup lang="ts">
useHead({ title: 'Log in' })

const { login } = useAuth()

const username = ref('')
const password = ref('')
const pending = ref(false)
const error = ref<string | null>(null)

async function onSubmit() {
  if (pending.value) return
  error.value = null
  pending.value = true
  try {
    await login(username.value, password.value)
    await navigateTo('/')
  } catch (err) {
    // 401 invalid credentials and 403 locked account both surface here.
    error.value = apiErrorMessage(err, 'Login failed. Try again.')
  } finally {
    pending.value = false
  }
}
</script>

<template>
  <div class="auth-wrap">
    <div class="panel">
      <h1 class="panel-title">Log in</h1>
      <p class="text-mist">Your game account opens this door too.</p>

      <p v-if="error" class="form-banner" role="alert">{{ error }}</p>

      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="login-username">Username</label>
          <input
            id="login-username"
            v-model="username"
            type="text"
            required
            autocomplete="username"
            maxlength="16"
          />
        </div>
        <div class="field">
          <label for="login-password">Password</label>
          <input
            id="login-password"
            v-model="password"
            type="password"
            required
            autocomplete="current-password"
            maxlength="16"
          />
        </div>
        <button type="submit" class="btn" :disabled="pending">
          {{ pending ? 'Entering…' : 'Enter the realm' }}
        </button>
      </form>
    </div>

    <p class="auth-foot">
      No account yet? <NuxtLink to="/register">Forge one.</NuxtLink>
    </p>
  </div>
</template>
