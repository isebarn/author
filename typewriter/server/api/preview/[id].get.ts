export default defineEventHandler(async (event) => {
  const id = Number(getRouterParam(event, 'id'))
  if (!id || isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  const sql = useDb()
  const [folder] = await sql`SELECT id, title FROM folder WHERE id = ${id}`
  if (!folder) {
    throw createError({ statusCode: 404, statusMessage: 'Chapter not found' })
  }

  const [text] = await sql`SELECT content FROM texts WHERE folder = ${id}`

  return {
    title: folder.title as string,
    content: (text?.content ?? '') as string,
  }
})
