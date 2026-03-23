export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body?.title || typeof body.title !== 'string') {
    throw createError({ statusCode: 400, statusMessage: 'title is required' })
  }

  const db = useDb()
  const parent = body.parent ?? null

  const result = db.prepare('INSERT INTO folder (title, parent) VALUES (?, ?)').run(body.title, parent)

  return db.prepare('SELECT id, parent, title FROM folder WHERE id = ?').get(result.lastInsertRowid)
})
