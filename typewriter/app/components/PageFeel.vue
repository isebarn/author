<script setup lang="ts">
import { useBookStore } from '~/stores/bookstore'

const store = useBookStore()
</script>

<template>
  <div class="page-outer" :class="store.fontFamily">
    <div class="page-feel">
      <div class="page-scroll">
        <div class="pre-spacer" />
        <slot name="content" />
        <div class="post-spacer" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-outer {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
  padding: 1.5rem 0;
  box-sizing: border-box;
}

.page-feel {
  height: 100%;
  width: 50%;
  background: white;
  border-radius: 1rem;
  overflow: hidden;

  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.04),
    0 4px 12px rgba(0, 0, 0, 0.05),
    4px 6px 16px rgba(0, 0, 0, 0.07),
    -4px 6px 16px rgba(0, 0, 0, 0.07),
    0 8px 20px rgba(0, 0, 0, 0.06);
}

.page-scroll {
  height: 100%;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  padding: 0 3rem;
  scrollbar-width: none;
}

.page-scroll::-webkit-scrollbar {
  display: none;
}

.pre-spacer {
  flex-shrink: 0;
  height: 50%;
}

.post-spacer {
  flex-shrink: 0;
  height: 50%;
}
</style>
