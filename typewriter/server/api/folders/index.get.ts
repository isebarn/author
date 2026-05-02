export default defineEventHandler(async () => {
  const sql = useDb()
  return await sql`SELECT id, parent, title, outline FROM folder`
})
