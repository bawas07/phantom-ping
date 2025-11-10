import { Database } from 'bun:sqlite';
import { env } from '@/config/env';
import { logger } from '@/logger';

let db: Database | null = null;

/**
 * Get or create database connection
 */
export function getDatabase(): Database {
  if (!db) {
    logger.info({ path: env.databasePath }, 'Initializing database connection');
    
    db = new Database(env.databasePath, { 
      create: true,
      strict: true,
    });

    // Enable foreign keys
    db.exec('PRAGMA foreign_keys = ON;');
    
    // Enable WAL mode for better concurrency
    db.exec('PRAGMA journal_mode = WAL;');
    
    logger.info('Database connection established');
  }

  return db;
}

/**
 * Close database connection
 */
export function closeDatabase(): void {
  if (db) {
    logger.info('Closing database connection');
    db.close();
    db = null;
  }
}

/**
 * Execute a query with parameters
 */
export function query<T = any>(sql: string, params?: any[]): T[] {
  const database = getDatabase();
  const stmt = database.prepare(sql);
  return stmt.all(...(params || [])) as T[];
}

/**
 * Execute a query and return the first result
 */
export function queryOne<T = any>(sql: string, params?: any[]): T | null {
  const database = getDatabase();
  const stmt = database.prepare(sql);
  return (stmt.get(...(params || [])) as T) || null;
}

/**
 * Execute a statement (INSERT, UPDATE, DELETE)
 */
export function execute(sql: string, params?: any[]): { changes: number; lastInsertRowid: number | bigint } {
  const database = getDatabase();
  const stmt = database.prepare(sql);
  return stmt.run(...(params || []));
}

/**
 * Execute multiple statements in a transaction
 */
export function transaction<T>(callback: () => T): T {
  const database = getDatabase();
  const tx = database.transaction(callback);
  return tx();
}
