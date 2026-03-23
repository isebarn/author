<script setup lang="ts">
const emit = defineEmits<{
  close: []
}>()
</script>

<template>
  <Teleport to="body">
    <div class="fixed inset-0 z-50 flex items-center justify-center" @click.self="emit('close')">
      <!-- backdrop -->
      <div class="absolute inset-0 bg-ink/10 backdrop-blur-[2px]" />

      <!-- modal -->
      <div class="relative bg-paper rounded-2xl shadow-xl border border-ink/5 w-full max-w-md mx-4 p-6">
        <div class="flex items-center justify-between mb-5">
          <h2 class="text-ink font-serif text-lg">Settings</h2>
          <button
            class="w-7 h-7 flex items-center justify-center rounded-lg text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
            @click="emit('close')"
          >
            <svg viewBox="0 0 16 16" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M4 4l8 8M12 4l-8 8" />
            </svg>
          </button>
        </div>

        <Typeface />
      </div>
    </div>
  </Teleport>
</template>
