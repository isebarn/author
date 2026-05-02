export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body?.title || typeof body.title !== 'string') {
    throw createError({ statusCode: 400, statusMessage: 'title is required' })
  }

  const sql = useDb()
  const parent = body.parent ?? null

  const [folder] = await sql`
    INSERT INTO folder (title, parent) VALUES (${body.title}, ${parent})
    RETURNING id, parent, title, outline
  `

  return folder
})
