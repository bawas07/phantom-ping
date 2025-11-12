import { queryOne, execute, transaction } from '@/db/connection';
import { 
  hashPIN,
  generateAccessToken,
  generateRefreshTokenString,
  hashRefreshToken
} from '@/utils/auth';
import { generateUUIDv7 } from '@/utils/idGenerator';

/**
 * User data structure from database
 */
interface User {
  id: string;
  organization_id: string;
  name: string;
  email: string;
  pin_hash: string;
  role: 'owner' | 'admin' | 'supervisor' | 'normal';
  supervisor_topic_id: string | null;
  notification_enabled: boolean;
  created_at: string;
  updated_at: string;
}

/**
 * User profile returned after successful authentication
 */
export interface UserProfile {
  userId: string;
  organizationId: string;
  name: string;
  email: string;
  role: 'owner' | 'admin' | 'supervisor' | 'normal';
  supervisorTopicId?: string;
  notificationEnabled: boolean;
}

/**
 * Login response structure
 */
export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: UserProfile;
}

/**
 * Token refresh response structure
 */
export interface RefreshResponse {
  accessToken: string;
  refreshToken: string;
}

/**
 * Authenticates a user with PIN and Organization ID
 * Returns access token, refresh token, and user profile
 * 
 * @param pin - User's PIN
 * @param organizationId - Organization ID
 * @returns Login response with tokens and user profile
 * @throws Error if credentials are invalid
 */
export async function login(pin: string, organizationId: string): Promise<LoginResponse> {
  // Hash the PIN to query the database
  const pinHash = hashPIN(pin);
  
  // Find user by organization ID and PIN hash
  const user = queryOne<User>(
    'SELECT * FROM users WHERE organization_id = ? AND pin_hash = ?',
    [organizationId, pinHash]
  );

  if (!user) {
    throw new Error('Invalid PIN or Organization ID');
  }

  // Generate tokens
  const accessToken = generateAccessToken(
    user.id,
    user.organization_id,
    user.role,
    user.supervisor_topic_id || undefined
  );

  // Generate refresh token string and hash it
  const refreshTokenString = generateRefreshTokenString();
  const refreshTokenHash = hashRefreshToken(refreshTokenString);

  // Store refresh token in database
  const refreshTokenId = generateUUIDv7();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // 7 days from now

  execute(
    'INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at) VALUES (?, ?, ?, ?)',
    [refreshTokenId, user.id, refreshTokenHash, expiresAt.toISOString()]
  );

  // Build user profile
  const userProfile: UserProfile = {
    userId: user.id,
    organizationId: user.organization_id,
    name: user.name,
    email: user.email,
    role: user.role,
    notificationEnabled: Boolean(user.notification_enabled),
  };

  if (user.supervisor_topic_id) {
    userProfile.supervisorTopicId = user.supervisor_topic_id;
  }

  return {
    accessToken,
    refreshToken: refreshTokenString,
    user: userProfile,
  };
}

/**
 * Refreshes access and refresh tokens using a valid refresh token
 * 
 * @param refreshToken - Current refresh token
 * @returns New access and refresh tokens
 * @throws Error if refresh token is invalid or expired
 */
export async function refreshTokens(refreshToken: string): Promise<RefreshResponse> {
  // Hash the provided refresh token
  const tokenHash = hashRefreshToken(refreshToken);

  // Find refresh token in database
  const storedToken = queryOne<{
    id: string;
    user_id: string;
    token_hash: string;
    expires_at: string;
  }>(
    'SELECT * FROM refresh_tokens WHERE token_hash = ?',
    [tokenHash]
  );

  if (!storedToken) {
    throw new Error('Invalid refresh token');
  }

  // Check if token is expired
  const expiresAt = new Date(storedToken.expires_at);
  if (expiresAt < new Date()) {
    // Clean up expired token
    execute('DELETE FROM refresh_tokens WHERE id = ?', [storedToken.id]);
    throw new Error('Refresh token has expired');
  }

  // Get user information
  const user = queryOne<User>(
    'SELECT * FROM users WHERE id = ?',
    [storedToken.user_id]
  );

  if (!user) {
    // Clean up orphaned token
    execute('DELETE FROM refresh_tokens WHERE id = ?', [storedToken.id]);
    throw new Error('User not found');
  }

  // Generate new tokens
  const newAccessToken = generateAccessToken(
    user.id,
    user.organization_id,
    user.role,
    user.supervisor_topic_id || undefined
  );

  const newRefreshTokenString = generateRefreshTokenString();
  const newRefreshTokenHash = hashRefreshToken(newRefreshTokenString);

  // Replace old refresh token with new one in a transaction
  transaction(() => {
    // Delete old refresh token
    execute('DELETE FROM refresh_tokens WHERE id = ?', [storedToken.id]);

    // Insert new refresh token
    const newRefreshTokenId = generateUUIDv7();
    const newExpiresAt = new Date();
    newExpiresAt.setDate(newExpiresAt.getDate() + 7); // 7 days from now

    execute(
      'INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at) VALUES (?, ?, ?, ?)',
      [newRefreshTokenId, user.id, newRefreshTokenHash, newExpiresAt.toISOString()]
    );
  });

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshTokenString,
  };
}

/**
 * Logs out a user by invalidating their refresh token
 * 
 * @param refreshToken - Refresh token to invalidate
 * @throws Error if refresh token is invalid
 */
export async function logout(refreshToken: string): Promise<void> {
  // Hash the provided refresh token
  const tokenHash = hashRefreshToken(refreshToken);

  // Delete refresh token from database
  const result = execute(
    'DELETE FROM refresh_tokens WHERE token_hash = ?',
    [tokenHash]
  );

  if (result.changes === 0) {
    throw new Error('Invalid refresh token');
  }
}
