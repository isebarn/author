export default defineEventHandler(async (event) => {
  const path = getRequestURL(event).pathname

  // Only track page requests — skip API routes, assets, and Nuxt internals
  if (
    path.startsWith('/api/') ||
    path.startsWith('/_') ||
    path.includes('.')
  ) return

  const ip = getRequestIP(event, { xForwardedFor: true }) ?? 'unknown'

  try {
    const sql = useDb()
    await sql`
      INSERT INTO visitors (ip, first_seen, last_seen, visit_count)
      VALUES (${ip}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1)
      ON CONFLICT (ip) DO UPDATE SET
        last_seen = CURRENT_TIMESTAMP,
        visit_count = visitors.visit_count + 1
    `
  } catch (_) { /* non-fatal */ }
})
