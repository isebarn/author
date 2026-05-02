<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const props = defineProps<{
  folderId: number
  folderTitle: string
}>()

const emit = defineEmits<{ close: [] }>()

const store = useBookStore()
const text = ref('')
const loading = ref(true)

onMounted(async () => {
  text.value = await store.loadOutline(props.folderId)
  loading.value = false
})

async function save() {
  await store.saveOutline(props.folderId, text.value)
  emit('close')
}

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
      <div class="bg-white rounded-xl shadow-xl w-[520px] max-h-[80vh] flex flex-col font-ui">
        <!-- header -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-ink/5">
          <span class="text-[13px] font-ui text-ink font-medium">Outline — {{ folderTitle }}</span>
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
        <div class="flex-1 overflow-hidden p-5">
          <div v-if="loading" class="text-ink-light/50 text-[13px] text-center py-8">Loading…</div>
          <textarea
            v-else
            v-model="text"
            class="w-full h-64 resize-none outline-none text-[13px] text-ink leading-relaxed placeholder:text-ink-light/40 font-ui"
            placeholder="Describe this story or chapter — setting, characters, tone, what happens. This context helps the writing coach give better feedback."
            autofocus
            @keydown.ctrl.enter="save"
            @keydown.meta.enter="save"
          />
        </div>

        <!-- footer -->
        <div class="px-5 py-3 border-t border-ink/5 flex justify-end gap-2">
          <button
            class="px-4 py-1.5 rounded text-[12px] font-ui text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
            @click="emit('close')"
          >
            Cancel
          </button>
          <button
            class="px-4 py-1.5 rounded text-[12px] font-ui bg-blue-100 hover:bg-blue-200 text-blue-700 transition-colors"
            @click="save"
          >
            Save
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
