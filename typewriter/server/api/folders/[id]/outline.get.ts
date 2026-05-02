export default defineEventHandler((event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const db = useDb()
  const row = db.prepare('SELECT outline FROM folder WHERE id = ?').get(id) as { outline: string } | undefined
  if (!row) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  return { outline: row.outline ?? '' }
})
