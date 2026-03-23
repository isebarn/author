export default defineEventHandler(async (event) => {
  const folderId = getRouterParam(event, 'folderId')
  if (!folderId) throw createError({ statusCode: 400, message: 'folderId required' })

  const body = await readBody(event)
  const content = body?.content ?? ''

  const db = useDb()
  const existing = db.prepare('SELECT id FROM texts WHERE folder = ?').get(Number(folderId))

  if (existing) {
    db.prepare('UPDATE texts SET content = ? WHERE folder = ?').run(content, Number(folderId))
  } else {
    db.prepare('INSERT INTO texts (folder, content) VALUES (?, ?)').run(Number(folderId), content)
  }

  return db.prepare('SELECT * FROM texts WHERE folder = ?').get(Number(folderId))
})
