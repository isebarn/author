<script setup lang="ts">
const props = defineProps<{
  feedback: string
  suggestion: string | null
  originalParagraph: string
  loading: boolean
}>()

const emit = defineEmits<{
  close: []
  accept: [text: string]
}>()

// ── Word-level diff ────────────────────────────────────────────────────────

type Token = { type: 'same' | 'del' | 'ins'; text: string }

function wordDiff(a: string, b: string): Token[] {
  const aw = a.split(' ')
  const bw = b.split(' ')
  const m = aw.length
  const n = bw.length

  // LCS table
  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0))
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = aw[i - 1] === bw[j - 1] ? dp[i - 1][j - 1] + 1 : Math.max(dp[i - 1][j], dp[i][j - 1])

  // Backtrack
  const tokens: Token[] = []
  let i = m, j = n
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && aw[i - 1] === bw[j - 1]) {
      tokens.unshift({ type: 'same', text: aw[i - 1] })
      i--; j--
    } else if (j > 0 && (i === 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      tokens.unshift({ type: 'ins', text: bw[j - 1] })
      j--
    } else {
      tokens.unshift({ type: 'del', text: aw[i - 1] })
      i--
    }
  }
  return tokens
}

const diffTokens = computed(() =>
  props.suggestion ? wordDiff(props.originalParagraph, props.suggestion) : []
)
</script>

<template>
  <div class="absolute right-6 bottom-24 w-80 coach-bubble font-ui z-40">
    <div class="bg-white rounded-2xl shadow-lg border border-ink/5 overflow-hidden">

      <!-- header -->
      <div class="flex items-center justify-between px-4 py-3 border-b border-ink/5">
        <span class="text-[12px] font-ui text-ink-light uppercase tracking-widest">Coach</span>
        <button
          class="w-5 h-5 flex items-center justify-center rounded text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
          @click="emit('close')"
        >
          <svg viewBox="0 0 16 16" class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M3 3l10 10M13 3L3 13" />
          </svg>
        </button>
      </div>

      <!-- body -->
      <div class="px-4 py-3">
        <!-- loading -->
        <div v-if="loading" class="flex items-center gap-2 text-ink-light/60 text-[12px]">
          <svg class="w-3.5 h-3.5 animate-spin shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
          </svg>
          Reading your paragraph…
        </div>

        <template v-else>
          <!-- feedback text -->
          <p class="text-[13px] text-ink leading-relaxed whitespace-pre-wrap font-ui">{{ feedback }}</p>

          <!-- diff view -->
          <div v-if="suggestion" class="mt-3 pt-3 border-t border-ink/5">
            <p class="text-[11px] text-ink-light uppercase tracking-widest mb-2">Suggested change</p>
            <p class="text-[12.5px] leading-relaxed font-ui">
              <template v-for="(token, i) in diffTokens" :key="i">
                <span
                  :class="{
                    'line-through text-red-400/80': token.type === 'del',
                    'bg-blue-50 text-blue-600 rounded px-0.5': token.type === 'ins',
                  }"
                >{{ token.text }}</span>{{ ' ' }}
              </template>
            </p>

            <!-- accept / reject -->
            <div class="flex gap-2 mt-3">
              <button
                class="flex-1 py-1.5 rounded text-[12px] font-ui text-ink-light hover:text-ink hover:bg-ink/5 transition-colors"
                @click="emit('close')"
              >
                Reject
              </button>
              <button
                class="flex-1 py-1.5 rounded text-[12px] font-ui bg-blue-100 hover:bg-blue-200 text-blue-700 transition-colors"
                @click="emit('accept', suggestion)"
              >
                Accept
              </button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- pointer triangle -->
    <div class="absolute bottom-[-6px] right-7 w-3 h-3 bg-white border-r border-b border-ink/5 rotate-45" />
  </div>
</template>

<style scoped>
.coach-bubble {
  animation: bubble-in 0.18s ease-out;
  transform-origin: bottom right;
}
@keyframes bubble-in {
  from { opacity: 0; transform: scale(0.92) translateY(6px); }
  to   { opacity: 1; transform: scale(1)    translateY(0); }
}
</style>
