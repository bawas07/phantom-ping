import { Database } from 'bun:sqlite';
import { getDatabase } from './connection';
import { logger } from '@/logger';
import { readdirSync, existsSync } from 'fs';
import { join } from 'path';

interface Migration {
  id: number;
  name: string;
  applied_at: string;
}

/**
 * Initialize migrations table
 */
function initMigrationsTable(db: Database): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS migrations (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

/**
 * Get list of applied migrations
 */
function getAppliedMigrations(db: Database): Set<string> {
  const stmt = db.prepare('SELECT name FROM migrations ORDER BY id');
  const rows = stmt.all() as Migration[];
  return new Set(rows.map(row => row.name));
}

/**
 * Get list of migration files from migrations directory
 */
function getMigrationFiles(migrationsDir: string): string[] {
  if (!existsSync(migrationsDir)) {
    logger.warn({ dir: migrationsDir }, 'Migrations directory does not exist');
    return [];
  }

  const files = readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  return files;
}

/**
 * Apply a single migration
 */
async function applyMigration(db: Database, migrationPath: string, migrationName: string): Promise<void> {
  logger.info({ migration: migrationName }, 'Applying migration');

  const sql = await Bun.file(migrationPath).text();
  
  const tx = db.transaction(() => {
    // Execute migration SQL
    db.exec(sql);
    
    // Record migration
    const stmt = db.prepare('INSERT INTO migrations (name) VALUES (?)');
    stmt.run(migrationName);
  });

  tx();

  logger.info({ migration: migrationName }, 'Migration applied successfully');
}

/**
 * Run all pending migrations
 */
export async function runMigrations(migrationsDir: string = join(process.cwd(), 'migrations')): Promise<void> {
  const db = getDatabase();

  logger.info({ dir: migrationsDir }, 'Starting migration process');

  // Initialize migrations table
  initMigrationsTable(db);

  // Get applied migrations
  const appliedMigrations = getAppliedMigrations(db);

  // Get migration files
  const migrationFiles = getMigrationFiles(migrationsDir);

  if (migrationFiles.length === 0) {
    logger.info('No migration files found');
    return;
  }

  // Apply pending migrations
  let appliedCount = 0;
  for (const file of migrationFiles) {
    if (!appliedMigrations.has(file)) {
      const migrationPath = join(migrationsDir, file);
      await applyMigration(db, migrationPath, file);
      appliedCount++;
    }
  }

  if (appliedCount === 0) {
    logger.info('All migrations are up to date');
  } else {
    logger.info({ count: appliedCount }, 'Migrations completed');
  }
}

/**
 * Get migration status
 */
export function getMigrationStatus(migrationsDir: string = join(process.cwd(), 'migrations')): {
  applied: string[];
  pending: string[];
} {
  const db = getDatabase();

  initMigrationsTable(db);

  const appliedMigrations = getAppliedMigrations(db);
  const migrationFiles = getMigrationFiles(migrationsDir);

  const applied = migrationFiles.filter(file => appliedMigrations.has(file));
  const pending = migrationFiles.filter(file => !appliedMigrations.has(file));

  return { applied, pending };
}
