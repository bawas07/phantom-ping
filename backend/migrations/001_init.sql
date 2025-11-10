-- Initial migration to test the migration system
-- This will be replaced by the actual schema in task 2.2

CREATE TABLE IF NOT EXISTS _test_migrations (
  id INTEGER PRIMARY KEY,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
