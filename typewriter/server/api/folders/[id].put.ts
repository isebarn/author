export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const db = useDb()
  const existing = db.prepare('SELECT id, parent, title FROM folder WHERE id = ?').get(id)
  if (!existing) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  const body = await readBody(event)
  const title = body?.title ?? (existing as any).title
  const parent = body?.parent !== undefined ? body.parent : (existing as any).parent

  db.prepare('UPDATE folder SET title = ?, parent = ? WHERE id = ?').run(title, parent, id)

  return db.prepare('SELECT id, parent, title FROM folder WHERE id = ?').get(id)
})
