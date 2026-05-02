export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const sql = useDb()
  const [row] = await sql`SELECT outline FROM folder WHERE id = ${id}`
  if (!row) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  return { outline: row.outline ?? '' }
})
