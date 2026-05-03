export default defineNitroPlugin(async () => {
  const sql = useDb()
  const isPg = !!process.env.DATABASE_URL

  if (isPg) {
    await sql`
      CREATE TABLE IF NOT EXISTS folder (
        id SERIAL PRIMARY KEY,
        parent INTEGER REFERENCES folder(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        outline TEXT NOT NULL DEFAULT ''
      )
    `
    await sql`
      CREATE TABLE IF NOT EXISTS texts (
        id SERIAL PRIMARY KEY,
        folder INTEGER UNIQUE REFERENCES folder(id) ON DELETE CASCADE,
        content TEXT NOT NULL DEFAULT ''
      )
    `
    await sql`
      CREATE TABLE IF NOT EXISTS coach_replies (
        id SERIAL PRIMARY KEY,
        folder INTEGER REFERENCES folder(id) ON DELETE CASCADE,
        paragraph TEXT,
        feedback TEXT NOT NULL,
        suggestion TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `
    // Upgrade existing tables
    await sql`ALTER TABLE coach_replies ADD COLUMN IF NOT EXISTS suggestion TEXT`
  } else {
    await sql`
      CREATE TABLE IF NOT EXISTS folder (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent INTEGER REFERENCES folder(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        outline TEXT NOT NULL DEFAULT ''
      )
    `
    await sql`
      CREATE TABLE IF NOT EXISTS texts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder INTEGER UNIQUE REFERENCES folder(id) ON DELETE CASCADE,
        content TEXT NOT NULL DEFAULT ''
      )
    `
    await sql`
      CREATE TABLE IF NOT EXISTS coach_replies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder INTEGER REFERENCES folder(id) ON DELETE CASCADE,
        paragraph TEXT,
        feedback TEXT NOT NULL,
        suggestion TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    `
    // Upgrade existing SQLite tables
    try { await sql`ALTER TABLE folder ADD COLUMN outline TEXT NOT NULL DEFAULT ''` } catch (_) {}
    try { await sql`ALTER TABLE coach_replies ADD COLUMN suggestion TEXT` } catch (_) {}
  }
})
