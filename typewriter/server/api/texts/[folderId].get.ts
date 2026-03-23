export default defineEventHandler((event) => {
  const folderId = getRouterParam(event, 'folderId')
  if (!folderId) throw createError({ statusCode: 400, message: 'folderId required' })

  const db = useDb()
  const row = db.prepare('SELECT * FROM texts WHERE folder = ?').get(Number(folderId))

  if (!row) {
    return { id: null, folder: Number(folderId), content: '' }
  }

  return row
})
