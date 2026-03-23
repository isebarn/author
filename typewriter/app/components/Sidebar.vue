<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()

const showModal = ref(false)
const showSettings = ref(false)

async function handleCreateFolder(name: string) {
  const folder = await store.createFolder(name)
  showModal.value = false
  store.openFolder(folder.id)
}
</script>

<template>
  <aside class="w-60 h-full bg-paper border-r border-ink/5 flex flex-col overflow-hidden font-ui">
    <!-- header -->
    <div class="flex items-center justify-between px-3 pt-3 pb-1">
      <span class="text-[11px] font-ui text-ink-light uppercase tracking-widest">Folders</span>
      <button
        class="w-5 h-5 flex items-center justify-center rounded text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
        title="New folder"
        @click="showModal = true"
      >
        <svg viewBox="0 0 16 16" class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M8 3v10M3 8h10" />
        </svg>
      </button>
    </div>

    <!-- tree -->
    <nav class="flex-1 overflow-y-auto px-1 pb-4 text-ink">
      <ul class="mt-0.5">
        <SidebarFolder
          v-for="node in store.folderTree"
          :key="node.id"
          :node="node"
        />
      </ul>

      <!-- empty state -->
      <div v-if="store.folderTree.length === 0" class="px-3 py-6 text-center">
        <p class="text-ink-light/50 text-[12px] font-ui">No folders yet</p>
      </div>
    </nav>

    <!-- footer with gear icon -->
    <div class="px-3 py-2 border-t border-ink/5">
      <button
        class="w-7 h-7 flex items-center justify-center rounded-lg text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
        title="Settings"
        @click="showSettings = true"
      >
        <svg viewBox="0 0 20 20" class="w-4 h-4" fill="currentColor">
          <path fill-rule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd" />
        </svg>
      </button>
    </div>

    <!-- modals -->
    <CreateFolderModal
      v-if="showModal"
      @confirm="handleCreateFolder"
      @cancel="showModal = false"
    />
    <Settings
      v-if="showSettings"
      @close="showSettings = false"
    />
  </aside>
</template>
