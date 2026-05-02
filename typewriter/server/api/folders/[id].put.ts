export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid folder id' })
  }

  const sql = useDb()
  const [existing] = await sql`SELECT id, parent, title FROM folder WHERE id = ${id}`
  if (!existing) {
    throw createError({ statusCode: 404, statusMessage: 'Folder not found' })
  }

  const body = await readBody(event)
  const title = body?.title ?? existing.title
  const parent = body?.parent !== undefined ? body.parent : existing.parent

  await sql`UPDATE folder SET title = ${title}, parent = ${parent} WHERE id = ${id}`

  const [folder] = await sql`SELECT id, parent, title, outline FROM folder WHERE id = ${id}`
  return folder
})
