export default defineEventHandler((event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const db = useDb()
  const result = db.prepare('DELETE FROM folder WHERE id = ?').run(id)

  if (result.changes === 0) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  return { success: true }
})
