#!/usr/bin/env bun
import { runMigrations } from '../src/db/migrations';
import { closeDatabase } from '../src/db/connection';
import { logger } from '../src/logger';

async function main() {
  try {
    logger.info('Running database migrations...');
    await runMigrations();
    logger.info('Migration process completed');
    closeDatabase();
    process.exit(0);
  } catch (error) {
    logger.error({ error }, 'Migration failed');
    closeDatabase();
    process.exit(1);
  }
}

main();
