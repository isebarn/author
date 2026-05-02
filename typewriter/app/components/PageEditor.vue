<script setup lang="ts">
import { onBeforeUnmount, onMounted, nextTick } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import { Decoration, DecorationSet } from '@tiptap/pm/view'
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()
let saveTimer: ReturnType<typeof setTimeout> | null = null

const showCoach = ref(false)
const coachLoading = ref(false)
const coachFeedback = ref('')
const shareCopied = ref(false)

function shareChapter() {
  if (!store.currentFolderId) return
  const url = `${window.location.origin}/preview/${store.currentFolderId}`
  navigator.clipboard.writeText(url)
  shareCopied.value = true
  setTimeout(() => { shareCopied.value = false }, 2000)
}

const ParagraphOpacity = Extension.create({
  name: 'paragraphOpacity',
  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('paragraphOpacity'),
        props: {
          decorations(state) {
            if (state.doc.childCount <= 1) return DecorationSet.empty
            const { $from } = state.selection
            const decos: Decoration[] = []
            state.doc.forEach((node, offset) => {
              if (node.type.name !== 'paragraph') return
              const isActive = $from.pos > offset && $from.pos < offset + node.nodeSize
              if (!isActive) {
                decos.push(Decoration.node(offset, offset + node.nodeSize, { class: 'inactive-para' }))
              }
            })
            return DecorationSet.create(state.doc, decos)
          },
        },
      }),
    ]
  },
})

const editor = useEditor({
  extensions: [StarterKit, ParagraphOpacity],
  content: store.currentContent,
  editorProps: {
    attributes: { class: 'outline-none' },
    handlePaste(view, event) {
      const text = event.clipboardData?.getData('text/plain') ?? ''
      view.dispatch(view.state.tr.insertText(text))
      return true
    },
  },
  onUpdate({ editor }) {
    if (store.currentFolderId === null) return
    store.setContent(store.currentFolderId, editor.getHTML())
    scheduleSave()
  },
  onSelectionUpdate({ editor }) {
    scrollParaToCenter(editor)
  },
})

function getActivePara(editor: ReturnType<typeof useEditor>['value']): HTMLElement | null {
  if (!editor) return null
  const pos = editor.state.selection.from
  let node: Node | null = editor.view.domAtPos(pos).node
  while (node && !(node instanceof HTMLElement && node.tagName === 'P')) {
    node = node.parentNode
  }
  return node instanceof HTMLElement ? node : null
}

function scrollParaToCenter(editor: ReturnType<typeof useEditor>['value'], instant = false) {
  const para = getActivePara(editor)
  if (!para) return
  const container = para.closest('.page-scroll') as HTMLElement | null
  if (!container) return
  const cRect = container.getBoundingClientRect()
  const pRect = para.getBoundingClientRect()
  const target = (pRect.top - cRect.top + container.scrollTop) + pRect.height / 2 - container.clientHeight / 2
  container.scrollTo({ top: Math.max(0, target), behavior: instant ? 'instant' : 'smooth' })
}

function scheduleSave() {
  if (saveTimer) clearTimeout(saveTimer)
  saveTimer = setTimeout(() => {
    if (store.currentFolderId !== null) store.saveContent(store.currentFolderId)
  }, 1000)
}

onMounted(() => {
  nextTick(() => {
    editor.value?.commands.focus('end')
    nextTick(() => scrollParaToCenter(editor.value, true))
  })
})

function getCurrentParagraphText(): string {
  if (!editor.value) return ''
  const { state } = editor.value
  const resolved = state.doc.resolve(state.selection.from)
  for (let d = resolved.depth; d >= 0; d--) {
    if (resolved.node(d).type.name === 'paragraph')
      return resolved.node(d).textContent
  }
  return ''
}

async function openCoach() {
  const currentFolder = store.folders.find(f => f.id === store.currentFolderId)
  if (!currentFolder) return

  const paraText = getCurrentParagraphText()
  const chapterOutline = await store.loadOutline(currentFolder.id)
  const bookOutline = currentFolder.parent
    ? await store.loadOutline(currentFolder.parent)
    : ''
  const bookTitle = currentFolder.parent
    ? (store.folders.find(f => f.id === currentFolder.parent)?.title ?? '')
    : currentFolder.title

  coachLoading.value = true
  coachFeedback.value = ''
  showCoach.value = true

  try {
    const res = await $fetch<{ feedback: string }>('/api/coach', {
      method: 'POST',
      body: {
        currentParagraph: paraText,
        chapterOutline,
        bookOutline,
        chapterText: store.currentContent,
        chapterTitle: currentFolder.title,
        bookTitle,
      },
    })
    coachFeedback.value = res.feedback
  } catch (e: any) {
    coachFeedback.value = `Error: ${e?.message ?? 'Could not reach the coach'}`
  } finally {
    coachLoading.value = false
  }
}

onBeforeUnmount(() => {
  if (saveTimer) {
    clearTimeout(saveTimer)
    if (store.currentFolderId !== null) store.saveContent(store.currentFolderId)
  }
  editor.value?.destroy()
})
</script>

<template>
  <div class="relative h-full">
    <PageFeel>
      <template #content>
        <EditorContent :editor="editor" class="text-editor text-ink w-full" />
      </template>
    </PageFeel>

    <!-- Share button -->
    <button
      class="absolute right-6 bottom-[5.5rem] w-8 h-8 rounded-full bg-blue-200/70 hover:bg-blue-300/90 shadow-sm flex items-center justify-center transition-colors"
      :title="shareCopied ? 'Copied!' : 'Copy share link'"
      @click="shareChapter"
    >
      <svg v-if="!shareCopied" viewBox="0 0 16 16" class="w-4 h-4 text-blue-600" fill="currentColor">
        <path d="M11 2a2 2 0 1 1 0 4 2 2 0 0 1 0-4zm-7 4a2 2 0 1 1 0 4 2 2 0 0 1 0-4zm7 4a2 2 0 1 1 0 4 2 2 0 0 1 0-4zM4.5 7.1l4 2.3-.6 1-4-2.3.6-1zm3.4-2.4.6 1-4 2.3-.6-1 4-2.3z"/>
      </svg>
      <svg v-else viewBox="0 0 16 16" class="w-4 h-4 text-blue-600" fill="currentColor">
        <path d="M13.5 2.5l-8 8-3-3-1 1 4 4 9-9-1-1z"/>
      </svg>
    </button>

    <!-- Writing Coach button -->
    <button
      class="absolute right-6 bottom-10 w-8 h-8 rounded-full bg-blue-200/70 hover:bg-blue-300/90 shadow-sm flex items-center justify-center transition-colors"
      title="Writing Coach"
      @click="openCoach"
    >
      <svg viewBox="0 0 16 16" class="w-4 h-4 text-blue-600" fill="currentColor">
        <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm.75 10.5h-1.5v-1.5h1.5v1.5zm0-3h-1.5C7.25 6.5 5.5 6 5.5 4.5 5.5 3.12 6.62 2 8 2s2.5 1.12 2.5 2.5c0 1.38-1.75 2-1.75 4z" />
      </svg>
    </button>

    <!-- Coach modal -->
    <CoachModal
      v-if="showCoach"
      :feedback="coachFeedback"
      :loading="coachLoading"
      @close="showCoach = false"
    />
  </div>
</template>

<style>
.tiptap {
  outline: none;
  caret-color: #00c4ff;
}

.tiptap p {
  margin: 0 0 0.4em;
  transition: opacity 0.3s ease;
}

.tiptap p:last-child {
  margin-bottom: 0;
}

.tiptap p.inactive-para {
  opacity: 0.3;
}
</style>
