<script setup lang="ts">
const props = withDefaults(defineProps<{
  text: string
  opacity?: number
}>(), {
  opacity: 0.35,
})

const emit = defineEmits<{
  edit: []
}>()

const rendered = computed(() => {
  return props.text
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/__(.+?)__/g, '<strong>$1</strong>')
    .replace(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, '<em>$1</em>')
    .replace(/(?<!_)_(?!_)(.+?)(?<!_)_(?!_)/g, '<em>$1</em>')
    .replace(/\n/g, '<br>')
})
</script>

<template>
  <div
    class="px-6 py-1 text-editor text-ink leading-relaxed cursor-pointer transition-opacity duration-200 hover:opacity-50"
    :style="{ opacity }"
    v-html="rendered"
    @click="emit('edit')"
  />
</template>
