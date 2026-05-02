<script setup lang="ts">
defineProps<{
  feedback: string
  loading: boolean
}>()

const emit = defineEmits<{ close: [] }>()

function onBackdrop(e: MouseEvent) {
  if (e.target === e.currentTarget) emit('close')
}
</script>

<template>
  <Teleport to="body">
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/20"
      @click="onBackdrop"
    >
      <div class="bg-white rounded-xl shadow-xl w-[480px] font-ui">
        <!-- header -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-ink/5">
          <span class="text-[13px] font-ui text-ink font-medium">Writing Coach</span>
          <button
            class="w-6 h-6 flex items-center justify-center rounded text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
            @click="emit('close')"
          >
            <svg viewBox="0 0 16 16" class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M3 3l10 10M13 3L3 13" />
            </svg>
          </button>
        </div>

        <!-- body -->
        <div class="px-5 py-5 min-h-[80px]">
          <!-- loading -->
          <div v-if="loading" class="flex items-center gap-2 text-ink-light/60 text-[13px]">
            <svg class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
            </svg>
            Reading your paragraph…
          </div>

          <!-- feedback -->
          <p
            v-else
            class="text-[13.5px] text-ink leading-relaxed whitespace-pre-wrap font-ui"
          >{{ feedback }}</p>
        </div>
      </div>
    </div>
  </Teleport>
</template>
