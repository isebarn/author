import postgres from 'postgres'

let _sql: ReturnType<typeof postgres> | null = null

export function useDb() {
  if (!_sql) {
    _sql = postgres(process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@localhost:5555/bookwriter')
  }
  return _sql
}
