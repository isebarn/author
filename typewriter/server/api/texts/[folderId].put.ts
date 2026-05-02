export default defineEventHandler(async (event) => {
  const folderId = getRouterParam(event, 'folderId')
  if (!folderId) throw createError({ statusCode: 400, message: 'folderId required' })

  const body = await readBody(event)
  const content = body?.content ?? ''

  const sql = useDb()
  const [row] = await sql`
    INSERT INTO texts (folder, content) VALUES (${Number(folderId)}, ${content})
    ON CONFLICT (folder) DO UPDATE SET content = EXCLUDED.content
    RETURNING *
  `

  return row
})
