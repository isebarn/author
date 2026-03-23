<script setup lang="ts">
const props = withDefaults(defineProps<{
  parentName?: string
}>(), {
  parentName: '',
})

const emit = defineEmits<{
  confirm: [name: string]
  cancel: []
}>()

const folderName = ref('')
const inputRef = ref<HTMLInputElement>()

function submit() {
  const name = folderName.value.trim()
  if (name) emit('confirm', name)
}

onMounted(() => {
  nextTick(() => inputRef.value?.focus())
})
</script>

<template>
  <Teleport to="body">
    <div class="fixed inset-0 z-50 flex items-center justify-center" @click.self="emit('cancel')">
      <!-- backdrop -->
      <div class="absolute inset-0 bg-ink/10 backdrop-blur-[2px]" />

      <!-- modal -->
      <div class="relative bg-paper rounded-xl shadow-xl border border-ink/5 w-full max-w-sm mx-4 p-6">
        <h2 class="text-ink font-serif text-lg mb-1">New Folder</h2>
        <p v-if="parentName" class="text-ink-light text-sm mb-4">
          Inside <span class="text-ink">{{ parentName }}</span>
        </p>
        <p v-else class="text-ink-light text-sm mb-4">Create a new folder</p>

        <input
          ref="inputRef"
          v-model="folderName"
          placeholder="Folder name…"
          class="w-full bg-transparent border-b-2 border-ink/10 focus:border-ink/30 outline-none text-ink font-serif text-base py-2 placeholder:text-ink-light/40 transition-colors"
          @keydown.enter="submit"
          @keydown.escape="emit('cancel')"
        />

        <div class="flex justify-end gap-3 mt-6">
          <button
            class="px-4 py-1.5 text-sm text-ink-light hover:text-ink transition-colors font-serif"
            @click="emit('cancel')"
          >
            Cancel
          </button>
          <button
            class="px-4 py-1.5 text-sm text-ink bg-ink/5 hover:bg-ink/10 rounded-lg transition-colors font-serif"
            :disabled="!folderName.trim()"
            :class="{ 'opacity-40 cursor-not-allowed': !folderName.trim() }"
            @click="submit"
          >
            Create
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
