<script setup lang="ts">
import { ref, watch, onMounted, nextTick } from 'vue'

const props = withDefaults(defineProps<{ modelValue?: string }>(), {
  modelValue: '',
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  submit: []
  'delete-back': []
}>()

const editorRef = ref<HTMLDivElement | null>(null)
let internalUpdate = false
let userEditing = false

function markdownToHtml(md: string): string {
  let html = md
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
  html = html.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
  html = html.replace(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, '<i>$1</i>')
  html = html.replace(/\n/g, '<br>')
  return html
}

function htmlToMarkdown(html: string): string {
  let md = html
  md = md.replace(/<br\s*\/?>/gi, '\n')
  md = md.replace(/<div><br><\/div>/gi, '\n')
  md = md.replace(/<div>/gi, '\n')
  md = md.replace(/<\/div>/gi, '')
  md = md.replace(/<b>(.*?)<\/b>/gi, '**$1**')
  md = md.replace(/<strong>(.*?)<\/strong>/gi, '**$1**')
  md = md.replace(/<i>(.*?)<\/i>/gi, '*$1*')
  md = md.replace(/<em>(.*?)<\/em>/gi, '*$1*')
  md = md.replace(/<[^>]+>/g, '')
  md = md.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&nbsp;/g, ' ')
  return md
}

function syncToEditor() {
  if (!editorRef.value) return
  const html = markdownToHtml(props.modelValue)
  if (editorRef.value.innerHTML !== html) {
    internalUpdate = true
    editorRef.value.innerHTML = html
    // Move cursor to end
    nextTick(() => {
      internalUpdate = false
      moveCursorToEnd()
    })
  }
}

function moveCursorToEnd() {
  if (!editorRef.value) return
  const sel = window.getSelection()
  if (!sel) return
  const range = document.createRange()
  range.selectNodeContents(editorRef.value)
  range.collapse(false)
  sel.removeAllRanges()
  sel.addRange(range)
  editorRef.value.focus()
}

function onInput() {
  if (internalUpdate || !editorRef.value) return
  userEditing = true
  const md = htmlToMarkdown(editorRef.value.innerHTML)
  emit('update:modelValue', md)
  nextTick(() => { userEditing = false })
}

function onPaste(e: ClipboardEvent) {
  e.preventDefault()
  const text = e.clipboardData?.getData('text/plain') || ''
  document.execCommand('insertText', false, text)
  onInput()
}

function onKeydown(e: KeyboardEvent) {
  // Backspace on empty → delete this text and go back
  if (e.key === 'Backspace' && !props.modelValue) {
    e.preventDefault()
    emit('delete-back')
    return
  }

  if ((e.ctrlKey || e.metaKey) && e.key === 'b') {
    e.preventDefault()
    document.execCommand('bold')
    onInput()
    return
  }

  if ((e.ctrlKey || e.metaKey) && e.key === 'i') {
    e.preventDefault()
    document.execCommand('italic')
    onInput()
    return
  }

  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    emit('submit')
    return
  }

  if (e.key === 'Enter' && e.shiftKey) {
    e.preventDefault()
    document.execCommand('insertLineBreak')
    onInput()
  }
}

watch(() => props.modelValue, () => {
  if (!internalUpdate && !userEditing) syncToEditor()
})

onMounted(() => {
  syncToEditor()
  editorRef.value?.focus()
})
</script>

<template>
  <div class="relative px-6 py-2">
    <div
      ref="editorRef"
      contenteditable="true"
      class="editor-area text-editor text-ink min-h-[3rem] outline-none focus:outline-none whitespace-pre-wrap break-words"
      :class="{ 'is-empty': !modelValue }"
      data-placeholder=""
      @input="onInput"
      @keydown="onKeydown"
      @paste="onPaste"
    />
  </div>
</template>

<style scoped>
.editor-area {
  caret-color: #00c4ff;
  outline: none;
  border: none;
  -webkit-user-modify: read-write;
  /* Scale up font slightly to get a slightly taller/more visible caret */
}

.editor-area:focus {
  outline: none;
}

.editor-area.is-empty::before {
  content: attr(data-placeholder);
  color: theme('colors.ink.light', #8a8a8a);
  pointer-events: none;
  position: absolute;
  opacity: 0.8;
}
</style>
