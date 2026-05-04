<script setup lang="ts">
interface Visitor {
  ip: string
  first_seen: string
  last_seen: string
  visit_count: number
}

const { data } = await useFetch<Visitor[]>('/api/visitors')

function fmt(ts: string) {
  return new Date(ts).toLocaleString(undefined, {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}
</script>

<template>
  <div class="min-h-screen bg-paper px-6 py-10 font-ui">
    <div class="max-w-3xl mx-auto">
      <h1 class="text-[11px] uppercase tracking-widest text-ink-light mb-6">Visitors</h1>

      <div class="bg-white rounded-xl shadow-sm border border-ink/5 overflow-hidden">
        <table class="w-full text-[13px] text-ink">
          <thead>
            <tr class="border-b border-ink/5 text-ink-light text-[11px] uppercase tracking-wider">
              <th class="text-left px-5 py-3 font-normal">IP</th>
              <th class="text-left px-5 py-3 font-normal">First seen</th>
              <th class="text-left px-5 py-3 font-normal">Last seen</th>
              <th class="text-right px-5 py-3 font-normal">Visits</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="v in data"
              :key="v.ip"
              class="border-b border-ink/5 last:border-0 hover:bg-ink/[0.02] transition-colors"
            >
              <td class="px-5 py-3 font-mono text-[12px]">{{ v.ip }}</td>
              <td class="px-5 py-3 text-ink-light">{{ fmt(v.first_seen) }}</td>
              <td class="px-5 py-3 text-ink-light">{{ fmt(v.last_seen) }}</td>
              <td class="px-5 py-3 text-right tabular-nums">{{ v.visit_count }}</td>
            </tr>
            <tr v-if="!data?.length">
              <td colspan="4" class="px-5 py-8 text-center text-ink-light/50">No visitors yet</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p class="mt-4 text-[11px] text-ink-light/40 text-right">{{ data?.length ?? 0 }} unique IPs</p>
    </div>
  </div>
</template>
