<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()

const emit = defineEmits<{
  'select-text': [id: number]
}>()

const subFolders = computed(() =>
  store.folders.filter((f) => f.parent === store.currentFolderId)
)

const texts = computed(() => store.currentFolderTexts)

const isEmpty = computed(() => subFolders.value.length === 0 && texts.value.length === 0)

function preview(text: string): string {
  return text.length > 50 ? text.slice(0, 50) + '…' : text
}

async function addText() {
  await store.createText(store.currentFolderId)
}

async function addFolder() {
  const title = prompt('Folder name')
  if (title?.trim()) {
    await store.createFolder(title.trim(), store.currentFolderId)
  }
}
</script>

<template>
  <div class="mx-auto w-full max-w-[900px] px-6 py-10">
    <!-- Empty state -->
    <div
      v-if="isEmpty"
      class="flex flex-col items-center justify-center py-24 text-center"
    >
      <p class="text-ink-light text-lg">No texts yet. Start writing!</p>
      <div class="mt-6 flex gap-3">
        <button
          class="rounded-lg border border-ink/10 px-5 py-2 text-sm text-ink transition-colors hover:border-ink/25"
          @click="addText"
        >
          New Text
        </button>
        <button
          class="rounded-lg border border-ink/10 px-5 py-2 text-sm text-ink transition-colors hover:border-ink/25"
          @click="addFolder"
        >
          New Folder
        </button>
      </div>
    </div>

    <!-- Grid -->
    <div
      v-else
      class="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4"
    >
      <!-- Sub-folders -->
      <button
        v-for="folder in subFolders"
        :key="'folder-' + folder.id"
        class="rounded-xl border border-ink/8 bg-paper px-5 py-5 text-left shadow-sm transition-all hover:border-ink/20 hover:shadow-md"
        @click="store.openFolder(folder.id)"
      >
        <span class="block truncate font-serif text-sm font-medium text-ink">
          {{ folder.title }}
        </span>
        <span class="mt-1 block text-xs text-ink-light">Folder</span>
      </button>

      <!-- Texts -->
      <button
        v-for="text in texts"
        :key="'text-' + text.id"
        class="rounded-xl border border-ink/8 bg-paper px-5 py-5 text-left shadow-sm transition-all hover:border-ink/20 hover:shadow-md"
        @click="emit('select-text', text.id)"
      >
        <span class="block text-sm leading-relaxed text-ink-light">
          {{ text.text ? preview(text.text) : 'Empty' }}
        </span>
      </button>

      <!-- New Text button -->
      <button
        class="flex items-center justify-center rounded-xl border border-dashed border-ink/15 bg-paper px-5 py-5 text-sm text-ink-light transition-all hover:border-ink/30 hover:text-ink"
        @click="addText"
      >
        + New Text
      </button>

      <!-- New Folder button -->
      <button
        class="flex items-center justify-center rounded-xl border border-dashed border-ink/15 bg-paper px-5 py-5 text-sm text-ink-light transition-all hover:border-ink/30 hover:text-ink"
        @click="addFolder"
      >
        + New Folder
      </button>
    </div>
  </div>
</template>
