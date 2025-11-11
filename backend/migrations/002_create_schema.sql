-- Phantom Ping Database Schema
-- This migration creates all core tables for the application

-- Organizations table
-- Stores organization data with user-provided ID (max 15 characters)
CREATE TABLE organizations (
  id TEXT PRIMARY KEY CHECK(length(id) <= 15),
  name TEXT NOT NULL,
  owner_id TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Topics table (created before users due to foreign key dependency)
-- Stores topic/sub-mesh data within organizations
CREATE TABLE topics (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
);

-- Users table
-- Stores user data with role-based access control
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('owner', 'admin', 'supervisor', 'normal')),
  supervisor_topic_id TEXT,
  notification_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(organization_id, pin_hash),
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (supervisor_topic_id) REFERENCES topics(id) ON DELETE SET NULL
);

-- Add foreign key constraint to organizations table for owner_id
-- Note: SQLite doesn't support adding foreign keys after table creation,
-- so this is documented for reference. The constraint is enforced at application level.

-- Topic memberships table
-- Many-to-many relationship between users and topics
CREATE TABLE topic_memberships (
  id TEXT PRIMARY KEY,
  topic_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(topic_id, user_id),
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Messages table
-- Stores broadcast messages with severity levels
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  level TEXT NOT NULL CHECK(level IN ('low', 'medium', 'high')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  code TEXT,
  scope TEXT NOT NULL CHECK(scope IN ('organization', 'topic')),
  topic_id TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(id),
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);

-- Message acknowledgements table
-- Tracks which users have acknowledged which messages
CREATE TABLE message_acknowledgements (
  id TEXT PRIMARY KEY,
  message_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  acknowledged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(message_id, user_id),
  FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Refresh tokens table
-- Stores refresh tokens for authentication
CREATE TABLE refresh_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Performance indexes
CREATE INDEX idx_users_org ON users(organization_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_supervisor_topic ON users(supervisor_topic_id);
CREATE INDEX idx_topics_org ON topics(organization_id);
CREATE INDEX idx_messages_org ON messages(organization_id);
CREATE INDEX idx_messages_topic ON messages(topic_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_topic_memberships_user ON topic_memberships(user_id);
CREATE INDEX idx_topic_memberships_topic ON topic_memberships(topic_id);
CREATE INDEX idx_message_acks_message ON message_acknowledgements(message_id);
CREATE INDEX idx_message_acks_user ON message_acknowledgements(user_id);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);
