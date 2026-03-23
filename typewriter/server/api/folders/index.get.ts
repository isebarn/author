export default defineEventHandler(() => {
  const db = useDb()
  return db.prepare('SELECT id, parent, title FROM folder').all()
})
