export default defineNitroPlugin(async () => {
  const sql = useDb()

  await sql`
    CREATE TABLE IF NOT EXISTS folder (
      id SERIAL PRIMARY KEY,
      parent INTEGER REFERENCES folder(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      outline TEXT NOT NULL DEFAULT ''
    )
  `

  await sql`
    CREATE TABLE IF NOT EXISTS texts (
      id SERIAL PRIMARY KEY,
      folder INTEGER UNIQUE REFERENCES folder(id) ON DELETE CASCADE,
      content TEXT NOT NULL DEFAULT ''
    )
  `
})
