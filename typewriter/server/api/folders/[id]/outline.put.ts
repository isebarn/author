export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const body = await readBody(event)
  const outline = typeof body?.outline === 'string' ? body.outline : ''

  const db = useDb()
  const existing = db.prepare('SELECT id FROM folder WHERE id = ?').get(id)
  if (!existing) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  db.prepare('UPDATE folder SET outline = ? WHERE id = ?').run(outline, id)

  return { outline }
})
