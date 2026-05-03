import postgres from 'postgres'
import { createRequire } from 'module'
import { join } from 'path'

// Tagged-template interface compatible with the postgres package
type SqlClient = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<any[]> & { count?: number }

let _client: SqlClient | null = null

// ── SQLite adapter (dev — no DATABASE_URL set) ─────────────────────────────

function createSqliteClient(): SqlClient {
  const _require = createRequire(import.meta.url)
  const Database = _require('better-sqlite3')
  const db = new Database(process.env.DB_PATH ?? join(process.cwd(), 'bookwriter.db'))
  db.pragma('journal_mode = WAL')
  db.pragma('foreign_keys = ON')

  return function (strings: TemplateStringsArray, ...values: unknown[]) {
    let query = ''
    for (let i = 0; i < strings.length; i++) {
      query += strings[i]
      if (i < values.length) query += '?'
    }
    query = query.trim()

    const isWrite = /^\s*(INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)/i.test(query)
    const hasReturning = /\bRETURNING\b/i.test(query)
    const stmt = db.prepare(query)

    if (isWrite && !hasReturning) {
      const info = stmt.run(...values)
      const result: any[] = []
      ;(result as any).count = info.changes ?? 0
      return Promise.resolve(result) as any
    }

    const rows = stmt.all(...values)
    ;(rows as any).count = rows.length
    return Promise.resolve(rows) as any
  }
}

// ── PostgreSQL client (prod — DATABASE_URL is set) ─────────────────────────

function createPostgresClient(): SqlClient {
  return postgres(process.env.DATABASE_URL!) as unknown as SqlClient
}

// ── Unified export ─────────────────────────────────────────────────────────

export function useDb(): SqlClient {
  if (!_client) {
    _client = process.env.DATABASE_URL
      ? createPostgresClient()
      : createSqliteClient()
  }
  return _client
}
