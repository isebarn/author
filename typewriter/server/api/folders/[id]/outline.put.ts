export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const body = await readBody(event)
  const outline = typeof body?.outline === 'string' ? body.outline : ''

  const sql = useDb()
  const [existing] = await sql`SELECT id FROM folder WHERE id = ${id}`
  if (!existing) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  await sql`UPDATE folder SET outline = ${outline} WHERE id = ${id}`

  return { outline }
})
