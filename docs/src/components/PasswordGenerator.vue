<script setup lang="ts">
import { onMounted, ref } from "vue";

// Only characters that are safe to paste into a `.env` file: no `$`, `#`,
// quotes, backslashes or spaces — Docker Compose and the shell would eat them.
const CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!%*+-.:=?@^_~";

const length = ref(24);
const password = ref("");
const copied = ref(false);

let copyTimeout: ReturnType<typeof setTimeout> | undefined;

function generate(): void
{
    const maxAcceptable = CHARSET.length * Math.floor(256 / CHARSET.length);
    const chars: string[] = [];
    const buffer = new Uint8Array(length.value * 2);

    while (chars.length < length.value)
    {
        crypto.getRandomValues(buffer);

        for (const byte of buffer)
        {
            if (byte < maxAcceptable && chars.length < length.value)
            {
                chars.push(CHARSET[byte % CHARSET.length]);
            }
        }
    }

    password.value = chars.join("");
    copied.value = false;
}
async function copy(): Promise<void>
{
    await navigator.clipboard.writeText(password.value);

    copied.value = true;

    clearTimeout(copyTimeout);
    copyTimeout = setTimeout(() => { copied.value = false; }, 2000);
}

onMounted(generate);
</script>

<template>
    <div class="password-generator">
        <div class="password-generator__row">
            <input class="password-generator__output"
                   type="text"
                   readonly
                   :value="password"
                   aria-label="Generated password"
                   @focus="($event.target as HTMLInputElement).select()" />
            <button class="password-generator__button password-generator__button--regenerate"
                    type="button"
                    aria-label="Generate a new password"
                    title="Generate a new password"
                    @click="generate">
                <svg xmlns="http://www.w3.org/2000/svg"
                     viewBox="0 0 24 24"
                     fill="none"
                     stroke="currentColor"
                     stroke-width="2"
                     stroke-linecap="round"
                     stroke-linejoin="round">
                    <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" />
                    <path d="M21 3v5h-5" />
                    <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16" />
                    <path d="M3 21v-5h5" />
                </svg>
            </button>
            <button class="password-generator__button password-generator__button--copy"
                    :class="{ 'password-generator__button--copied': copied }"
                    type="button"
                    aria-label="Copy to clipboard"
                    :title="copied ? 'Copied!' : 'Copy to clipboard'"
                    @click="copy">
            </button>
        </div>
        <label class="password-generator__length">
            <span>Length: <strong>{{ length }}</strong> characters</span>
            <input type="range"
                   min="12"
                   max="64"
                   v-model.number="length"
                   @input="generate" />
        </label>
    </div>
</template>

<style scoped>
.password-generator
{
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin: 16px 0;
    padding: 16px;
    border-radius: 8px;
    background-color: var(--vp-c-bg-soft);
}

.password-generator__row
{
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.password-generator__output
{
    flex: 1 1 200px;
    min-width: 0;
    padding: 0 12px;
    border: 1px solid var(--vp-c-divider);
    border-radius: 8px;
    background-color: var(--vp-c-bg);
    color: var(--vp-c-text-1);
    font-family: var(--vp-font-family-mono);
    font-size: 14px;
    line-height: 38px;
}
.password-generator__output:focus
{
    border-color: var(--vp-c-brand-1);
    outline: none;
}

/* Same look and feel as VitePress' native code-block copy button. */
.password-generator__button
{
    width: 40px;
    height: 40px;
    border: 1px solid var(--vp-code-copy-code-border-color);
    border-radius: 4px;
    background-color: var(--vp-code-copy-code-bg);
    transition: border-color 0.25s, background-color 0.25s;
}
.password-generator__button:hover
{
    border-color: var(--vp-code-copy-code-hover-border-color);
    background-color: var(--vp-code-copy-code-hover-bg);
}

.password-generator__button--regenerate
{
    display: inline-flex;
    align-items: center;
    justify-content: center;
    color: rgba(128, 128, 128, 1);
}
.password-generator__button--regenerate svg
{
    width: 20px;
    height: 20px;
}

.password-generator__button--copy
{
    background-image: var(--vp-icon-copy);
    background-position: 50%;
    background-size: 20px;
    background-repeat: no-repeat;
}
.password-generator__button--copied
{
    border-color: var(--vp-code-copy-code-hover-border-color);
    border-radius: 0 4px 4px 0;
    background-color: var(--vp-code-copy-code-hover-bg);
    background-image: var(--vp-icon-copied);
}
.password-generator__button--copied::before
{
    content: var(--vp-code-copy-copied-text-content);
    position: relative;
    top: -1px;
    transform: translateX(calc(-100% - 1px));
    display: flex;
    justify-content: center;
    align-items: center;
    border: 1px solid var(--vp-code-copy-code-hover-border-color);
    border-right: 0;
    border-radius: 4px 0 0 4px;
    padding: 0 10px;
    width: fit-content;
    height: 40px;
    text-align: center;
    font-size: 12px;
    font-weight: 500;
    color: var(--vp-code-copy-code-active-text);
    background-color: var(--vp-code-copy-code-hover-bg);
    white-space: nowrap;
}

.password-generator__length
{
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
    color: var(--vp-c-text-2);
    font-size: 14px;
}
.password-generator__length span
{
    flex: 0 0 auto;
}
.password-generator__length strong
{
    color: var(--vp-c-text-1);
}
.password-generator__length input
{
    flex: 1 1 160px;
    accent-color: var(--vp-c-brand-1);
}
</style>
