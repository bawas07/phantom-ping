import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { execute, queryOne } from '@/db/connection';
import { hashPIN } from '@/utils/auth';
import { generateUUIDv7 } from '@/utils/idGenerator';

/**
 * Integration tests for authentication service and endpoints
 * These tests verify the complete authentication flow including database operations
 */

describe('Authentication Integration', () => {
  let testUserId: string;
  let testOrgId: string;
  let testPin: string;
  let refreshToken: string;

  beforeAll(() => {
    // Create test organization and user
    testOrgId = 'TEST-ORG';
    testPin = '123456';
    testUserId = generateUUIDv7();

    // Create organization
    execute(
      'INSERT INTO organizations (id, name, owner_id) VALUES (?, ?, ?)',
      [testOrgId, 'Test Organization', testUserId]
    );

    // Create user
    const pinHash = hashPIN(testPin);
    execute(
      'INSERT INTO users (id, organization_id, name, email, pin_hash, role, notification_enabled) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [testUserId, testOrgId, 'Test User', 'test@example.com', pinHash, 'owner', true]
    );
  });

  afterAll(() => {
    // Clean up test data
    execute('DELETE FROM refresh_tokens WHERE user_id = ?', [testUserId]);
    execute('DELETE FROM users WHERE id = ?', [testUserId]);
    execute('DELETE FROM organizations WHERE id = ?', [testOrgId]);
  });

  test('should authenticate user with valid PIN and organization ID', async () => {
    const { login } = await import('@/services/authService');
    
    const result = await login(testPin, testOrgId);

    expect(result).toBeDefined();
    expect(result.accessToken).toBeDefined();
    expect(result.refreshToken).toBeDefined();
    expect(result.user).toBeDefined();
    expect(result.user.userId).toBe(testUserId);
    expect(result.user.organizationId).toBe(testOrgId);
    expect(result.user.name).toBe('Test User');
    expect(result.user.email).toBe('test@example.com');
    expect(result.user.role).toBe('owner');
    expect(result.user.notificationEnabled).toBe(true);

    // Store refresh token for next test
    refreshToken = result.refreshToken;

    // Verify refresh token was stored in database
    const storedToken = queryOne(
      'SELECT * FROM refresh_tokens WHERE user_id = ?',
      [testUserId]
    );
    expect(storedToken).toBeDefined();
  });

  test('should reject invalid PIN', async () => {
    const { login } = await import('@/services/authService');
    
    await expect(login('wrong-pin', testOrgId)).rejects.toThrow('Invalid PIN or Organization ID');
  });

  test('should reject invalid organization ID', async () => {
    const { login } = await import('@/services/authService');
    
    await expect(login(testPin, 'INVALID-ORG')).rejects.toThrow('Invalid PIN or Organization ID');
  });

  test('should refresh tokens with valid refresh token', async () => {
    const { refreshTokens } = await import('@/services/authService');
    
    const result = await refreshTokens(refreshToken);

    expect(result).toBeDefined();
    expect(result.accessToken).toBeDefined();
    expect(result.refreshToken).toBeDefined();
    expect(result.refreshToken).not.toBe(refreshToken); // Should be a new token

    // Update refresh token for next test
    refreshToken = result.refreshToken;
  });

  test('should reject invalid refresh token', async () => {
    const { refreshTokens } = await import('@/services/authService');
    
    await expect(refreshTokens('invalid-token')).rejects.toThrow('Invalid refresh token');
  });

  test('should logout and invalidate refresh token', async () => {
    const { logout, refreshTokens } = await import('@/services/authService');
    
    // Logout
    await logout(refreshToken);

    // Verify token was removed from database
    const storedToken = queryOne(
      'SELECT * FROM refresh_tokens WHERE user_id = ?',
      [testUserId]
    );
    expect(storedToken).toBeNull();

    // Verify token can no longer be used
    await expect(refreshTokens(refreshToken)).rejects.toThrow('Invalid refresh token');
  });
});
