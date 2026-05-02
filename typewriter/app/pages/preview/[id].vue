<script setup lang="ts">
const route = useRoute()
const id = route.params.id as string

const { data, error } = await useFetch(`/api/preview/${id}`)

if (error.value) {
  throw createError({ statusCode: 404, statusMessage: 'Chapter not found' })
}

useHead({
  title: data.value?.title ?? 'Preview',
})
</script>

<template>
  <div class="min-h-screen bg-white sm:bg-paper sm:py-10 sm:px-4 font-typewriter">
    <div class="mx-auto w-full max-w-[680px]">
      <!-- Paper card -->
      <div
        class="bg-white sm:rounded-2xl px-5 py-8 sm:px-14 sm:py-16"
        style="box-shadow: 0 1px 3px rgba(0,0,0,.04), 0 4px 12px rgba(0,0,0,.05), 4px 6px 16px rgba(0,0,0,.07), -4px 6px 16px rgba(0,0,0,.07), 0 8px 20px rgba(0,0,0,.06);"
      >
        <!-- Title -->
        <h1 class="text-[1rem] sm:text-[1.1rem] text-ink/50 mb-8 tracking-wide font-typewriter">
          {{ data?.title }}
        </h1>

        <!-- Content -->
        <div
          class="preview-content text-ink font-typewriter"
          v-html="data?.content"
        />
      </div>
    </div>
  </div>
</template>

<style>
.preview-content p {
  font-size: 1.18rem;
  line-height: 1.9;
  letter-spacing: 0.01em;
  margin: 0 0 0.4em;
}

@media (min-width: 640px) {
  .preview-content p {
    font-size: 1.08rem;
  }
}

.preview-content p:last-child {
  margin-bottom: 0;
}

.preview-content b,
.preview-content strong {
  font-weight: 600;
}

.preview-content em,
.preview-content i {
  font-style: italic;
}
</style>
