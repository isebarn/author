import Database from 'better-sqlite3'
import { join } from 'path'

const dbPath = join(process.cwd(), 'bookwriter.db')

const db = new Database(dbPath)

db.pragma('journal_mode = WAL')
db.pragma('foreign_keys = ON')

db.exec(`
  CREATE TABLE IF NOT EXISTS folder (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent INTEGER REFERENCES folder(id) ON DELETE CASCADE,
    title TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS texts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    folder INTEGER UNIQUE REFERENCES folder(id) ON DELETE CASCADE,
    content TEXT NOT NULL DEFAULT ''
  );
`)

try {
  db.exec(`ALTER TABLE folder ADD COLUMN outline TEXT NOT NULL DEFAULT ''`)
} catch (_) {
  // column already exists
}

export function useDb() {
  return db
}
