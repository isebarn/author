<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()

// Clicking a folder goes straight to editing — no overview needed
// If no folder is selected, show a prompt to select one
</script>

<template>
  <div class="flex-1 overflow-y-auto h-full">
    <div v-if="store.currentFolderId !== null" class="h-full">
      <PageEditor :key="store.currentFolderId" />
    </div>
  </div>
</template>
