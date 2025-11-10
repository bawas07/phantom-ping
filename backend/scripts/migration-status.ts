#!/usr/bin/env bun
import { getMigrationStatus } from '../src/db/migrations';
import { closeDatabase } from '../src/db/connection';
import { logger } from '../src/logger';

function main() {
  try {
    const status = getMigrationStatus();
    
    console.log('\n=== Migration Status ===\n');
    
    if (status.applied.length > 0) {
      console.log('Applied migrations:');
      status.applied.forEach(name => console.log(`  ✓ ${name}`));
    } else {
      console.log('No migrations applied yet.');
    }
    
    console.log('');
    
    if (status.pending.length > 0) {
      console.log('Pending migrations:');
      status.pending.forEach(name => console.log(`  ○ ${name}`));
    } else {
      console.log('No pending migrations.');
    }
    
    console.log('');
    
    closeDatabase();
    process.exit(0);
  } catch (error) {
    logger.error({ error }, 'Failed to get migration status');
    closeDatabase();
    process.exit(1);
  }
}

main();
