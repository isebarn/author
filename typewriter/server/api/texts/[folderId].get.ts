export default defineEventHandler(async (event) => {
  const folderId = getRouterParam(event, 'folderId')
  if (!folderId) throw createError({ statusCode: 400, message: 'folderId required' })

  const sql = useDb()
  const [row] = await sql`SELECT * FROM texts WHERE folder = ${Number(folderId)}`

  if (!row) {
    return { id: null, folder: Number(folderId), content: '' }
  }

  return row
})
