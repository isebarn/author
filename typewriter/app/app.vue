<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()
const route = useRoute()
const isPreview = computed(() => route.path.startsWith('/preview'))

// Load all data on app mount (skip for preview pages — they fetch independently)
onMounted(async () => {
  if (!isPreview.value) {
    await store.loadAll()
    window.addEventListener('keydown', handleGlobalKeydown)
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleGlobalKeydown)
})

function handleGlobalKeydown(e: KeyboardEvent) {
  // Ctrl+F → toggle focus mode
  if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
    e.preventDefault()
    store.toggleFocusMode()
    if (store.focusMode) {
      document.documentElement.requestFullscreen?.()
    } else {
      document.exitFullscreen?.()
    }
  }
}
</script>

<template>
  <!-- Preview pages render standalone, no sidebar or store loading -->
  <NuxtPage v-if="isPreview" />

  <!-- Main app -->
  <div v-else class="flex h-screen bg-paper overflow-hidden">
    <!-- Sidebar -->
    <transition name="slide">
      <Sidebar
        v-if="!store.focusMode"
        class="flex-shrink-0"
      />
    </transition>

    <!-- Main content -->
    <main class="flex-1 overflow-y-auto">
      <NuxtPage v-if="store.loaded" />
      <div v-else class="flex items-center justify-center h-full">
        <svg class="animate-spin w-6 h-6 text-ink-light" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2.5" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
      </div>
    </main>
  </div>
</template>

<style>
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.25s ease, opacity 0.25s ease;
}
.slide-enter-from,
.slide-leave-to {
  transform: translateX(-100%);
  opacity: 0;
}
</style>
