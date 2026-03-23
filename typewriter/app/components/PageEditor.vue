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

onBeforeUnmount(() => {
  if (saveTimer) {
    clearTimeout(saveTimer)
    if (store.currentFolderId !== null) store.saveContent(store.currentFolderId)
  }
  editor.value?.destroy()
})
</script>

<template>
  <PageFeel>
    <template #content>
      <EditorContent :editor="editor" class="text-editor text-ink w-full" />
    </template>
  </PageFeel>
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
