<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()

const fonts = [
  { label: 'Lora', class: 'font-lora', sample: 'The quick brown fox' },
  { label: 'Literata', class: 'font-literata', sample: 'The quick brown fox' },
  { label: 'Crimson Pro', class: 'font-crimson', sample: 'The quick brown fox' },
  { label: 'EB Garamond', class: 'font-garamond', sample: 'The quick brown fox' },
  { label: 'Typewriter', class: 'font-typewriter', sample: 'The quick brown fox' },
]
</script>

<template>
  <div>
    <h3 class="text-sm text-ink-light uppercase tracking-wider mb-3">Typeface</h3>
    <div class="flex flex-col gap-2">
      <button
        v-for="font in fonts"
        :key="font.class"
        class="flex items-center gap-4 rounded-xl px-4 py-3 text-left transition-all border"
        :class="[
          font.class,
          store.fontFamily === font.class
            ? 'border-ink/20 bg-ink/[0.03]'
            : 'border-transparent hover:border-ink/10 hover:bg-ink/[0.01]'
        ]"
        @click="store.fontFamily = font.class"
      >
        <span class="text-editor text-ink flex-1">{{ font.sample }}</span>
        <span class="text-xs text-ink-light shrink-0">{{ font.label }}</span>
        <svg
          v-if="store.fontFamily === font.class"
          viewBox="0 0 16 16"
          class="w-4 h-4 text-ink shrink-0"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
        >
          <path d="M3 8.5l3.5 3.5L13 4" />
        </svg>
      </button>
    </div>
  </div>
</template>
