export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const sql = useDb()
  const result = await sql`DELETE FROM folder WHERE id = ${id}`

  if (result.count === 0) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  return { success: true }
})
