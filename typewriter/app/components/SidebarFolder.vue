<script setup lang="ts">
import type { FolderTreeNode } from '~/stores/bookstore'
import { useBookStore } from '~/stores/bookstore'

const props = defineProps<{
  node: FolderTreeNode
  depth?: number
}>()

const store = useBookStore()
const depth = props.depth ?? 0

const collapsed = ref(false)
const editing = ref(false)
const editTitle = ref('')
const editInput = ref<HTMLInputElement>()
const showMenu = ref(false)
const showSubfolderModal = ref(false)
const showOutline = ref(false)

const isActive = computed(() => store.currentFolderId === props.node.id)
const hasChildren = computed(() => props.node.children.length > 0)

function toggle() {
  if (hasChildren.value) collapsed.value = !collapsed.value
}

function open() {
  store.openFolder(props.node.id)
}

function onContextMenu(e: MouseEvent) {
  e.preventDefault()
  showMenu.value = !showMenu.value
}

function startRename() {
  showMenu.value = false
  editTitle.value = props.node.title
  editing.value = true
  nextTick(() => editInput.value?.focus())
}

async function commitRename() {
  const title = editTitle.value.trim()
  if (title && title !== props.node.title) {
    await store.updateFolder(props.node.id, { title })
  }
  editing.value = false
}

async function remove() {
  showMenu.value = false
  await store.deleteFolder(props.node.id)
}

async function handleCreateSubfolder(name: string) {
  const folder = await store.createFolder(name, props.node.id)
  showSubfolderModal.value = false
  collapsed.value = false
  store.openFolder(folder.id)
}

function closeMenu(e: Event) {
  if (showMenu.value) showMenu.value = false
}

onMounted(() => document.addEventListener('click', closeMenu))
onUnmounted(() => document.removeEventListener('click', closeMenu))
</script>

<template>
  <li class="select-none">
    <div
      class="group flex items-center gap-1 rounded px-2 py-0.5 cursor-pointer text-[13px] leading-6 transition-colors"
      :class="[
        isActive ? 'bg-ink/5 text-ink' : 'text-ink-light hover:text-ink hover:bg-ink/[0.02]',
      ]"
      :style="{ paddingLeft: `${depth * 14 + 8}px` }"
      @click="open"
      @contextmenu="onContextMenu"
    >
      <!-- collapse chevron -->
      <button
        v-if="hasChildren"
        class="w-4 h-4 flex items-center justify-center text-ink-light shrink-0"
        @click.stop="toggle"
      >
        <svg
          class="w-3 h-3 transition-transform"
          :class="{ '-rotate-90': collapsed }"
          viewBox="0 0 16 16"
          fill="currentColor"
        >
          <path d="M4.5 6l3.5 4 3.5-4z" />
        </svg>
      </button>
      <span v-else class="w-4 shrink-0" />

      <!-- title / inline rename -->
      <input
        v-if="editing"
        ref="editInput"
        v-model="editTitle"
        class="flex-1 min-w-0 bg-transparent outline-none border-b border-ink/10 text-ink font-ui text-[13px] py-0"
        @keydown.enter="commitRename"
        @keydown.escape="editing = false"
        @blur="commitRename"
        @click.stop
      />
      <span v-else class="flex-1 min-w-0 truncate font-ui">{{ node.title }}</span>

      <!-- outline circle -->
      <button
        class="w-3.5 h-3.5 rounded-full bg-blue-200/80 hover:bg-blue-300 shrink-0 transition-colors"
        title="Outline / Story context"
        @click.stop="showOutline = true"
      />

      <!-- hover + icon for subfolder -->
      <button
        class="w-5 h-5 flex items-center justify-center opacity-0 group-hover:opacity-60 hover:!opacity-100 text-ink-light shrink-0"
        title="New subfolder"
        @click.stop="showSubfolderModal = true"
      >
        <svg viewBox="0 0 16 16" class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M8 4v8M4 8h8" />
        </svg>
      </button>

      <!-- actions dot -->
      <button
        class="w-5 h-5 flex items-center justify-center opacity-0 group-hover:opacity-60 hover:!opacity-100 text-ink-light shrink-0"
        @click.stop="showMenu = !showMenu"
      >
        <svg viewBox="0 0 16 16" class="w-3 h-3" fill="currentColor">
          <circle cx="8" cy="3" r="1.2" />
          <circle cx="8" cy="8" r="1.2" />
          <circle cx="8" cy="13" r="1.2" />
        </svg>
      </button>
    </div>

    <!-- context menu -->
    <div
      v-if="showMenu"
      class="ml-8 my-0.5 bg-white border border-ink/10 rounded shadow-sm text-[12px] text-ink-light w-28 overflow-hidden z-50"
    >
      <button class="w-full text-left px-3 py-1 hover:bg-ink/5" @click.stop="startRename">
        Rename
      </button>
      <button class="w-full text-left px-3 py-1 hover:bg-ink/5 text-red-500/80" @click.stop="remove">
        Delete
      </button>
    </div>

    <!-- children -->
    <ul v-if="hasChildren && !collapsed">
      <SidebarFolder
        v-for="child in node.children"
        :key="child.id"
        :node="child"
        :depth="depth + 1"
      />
    </ul>

    <!-- subfolder modal -->
    <CreateFolderModal
      v-if="showSubfolderModal"
      :parent-name="node.title"
      @confirm="handleCreateSubfolder"
      @cancel="showSubfolderModal = false"
    />

    <!-- outline modal -->
    <OutlineModal
      v-if="showOutline"
      :folder-id="node.id"
      :folder-title="node.title"
      @close="showOutline = false"
    />
  </li>
</template>
