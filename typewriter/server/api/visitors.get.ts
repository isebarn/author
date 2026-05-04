export default defineEventHandler(async () => {
  const sql = useDb()
  return await sql`SELECT ip, first_seen, last_seen, visit_count FROM visitors ORDER BY last_seen DESC`
})
