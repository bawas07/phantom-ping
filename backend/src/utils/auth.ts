import crypto from 'crypto';
import { env } from '@/config/env';

/**
 * Hashes a PIN using SHA-256
 * @param pin - The plain text PIN to hash
 * @returns The hashed PIN as a hex string
 */
export function hashPIN(pin: string): string {
  return crypto.createHash('sha256').update(pin).digest('hex');
}

/**
 * Verifies a plain text PIN against a hashed PIN
 * @param pin - The plain text PIN to verify
 * @param hashedPIN - The hashed PIN to compare against
 * @returns True if the PIN matches, false otherwise
 */
export function verifyPIN(pin: string, hashedPIN: string): boolean {
  const hash = hashPIN(pin);
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(hashedPIN));
}

/**
 * JWT payload structure for access tokens
 */
export interface JWTPayload {
  userId: string;
  organizationId: string;
  role: 'owner' | 'admin' | 'supervisor' | 'normal';
  supervisorTopicId?: string;
  type: 'access' | 'refresh';
}

/**
 * Generates an access token (15-minute expiration)
 * @param userId - The user's ID
 * @param organizationId - The user's organization ID
 * @param role - The user's role
 * @param supervisorTopicId - Optional topic ID if user is a supervisor
 * @returns The signed access token
 */
export function generateAccessToken(
  userId: string,
  organizationId: string,
  role: 'owner' | 'admin' | 'supervisor' | 'normal',
  supervisorTopicId?: string
): string {
  const payload: JWTPayload = {
    userId,
    organizationId,
    role,
    supervisorTopicId,
    type: 'access',
  };
  
  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const exp = now + parseExpiry(env.jwtAccessExpiry);

  const tokenPayload = {
    ...payload,
    iat: now,
    exp,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(tokenPayload));
  const signature = sign(`${encodedHeader}.${encodedPayload}`, env.jwtSecret);

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

/**
 * Generates a refresh token (7-day expiration)
 * @param userId - The user's ID
 * @param organizationId - The user's organization ID
 * @param role - The user's role
 * @param supervisorTopicId - Optional topic ID if user is a supervisor
 * @returns The signed refresh token
 */
export function generateRefreshToken(
  userId: string,
  organizationId: string,
  role: 'owner' | 'admin' | 'supervisor' | 'normal',
  supervisorTopicId?: string
): string {
  const payload: JWTPayload = {
    userId,
    organizationId,
    role,
    supervisorTopicId,
    type: 'refresh',
  };
  
  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const exp = now + parseExpiry(env.jwtRefreshExpiry);

  const tokenPayload = {
    ...payload,
    iat: now,
    exp,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(tokenPayload));
  const signature = sign(`${encodedHeader}.${encodedPayload}`, env.jwtSecret);

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

/**
 * Verifies and decodes a JWT token
 * @param token - The JWT token to verify
 * @returns The decoded payload if valid
 * @throws Error if token is invalid or expired
 */
export function verifyToken(token: string): JWTPayload {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('Invalid token format');
  }

  const [encodedHeader, encodedPayload, signature] = parts as [string, string, string];
  
  // Verify signature
  const expectedSignature = sign(`${encodedHeader}.${encodedPayload}`, env.jwtSecret);
  if (signature !== expectedSignature) {
    throw new Error('Invalid token signature');
  }

  // Decode payload
  const payload = JSON.parse(base64UrlDecode(encodedPayload)) as JWTPayload & {
    iat: number;
    exp: number;
  };

  // Check expiration
  const now = Math.floor(Date.now() / 1000);
  if (payload.exp < now) {
    throw new Error('Token expired');
  }

  return payload;
}

/**
 * Generates a cryptographically secure random refresh token string
 * This is used as the actual token value stored in the database
 * @returns A random hex string (64 characters)
 */
export function generateRefreshTokenString(): string {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Hashes a refresh token for storage in the database
 * @param token - The plain text refresh token
 * @returns The hashed token as a hex string
 */
export function hashRefreshToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// Helper functions

/**
 * Base64 URL-safe encoding
 */
function base64UrlEncode(str: string): string {
  return Buffer.from(str)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * Base64 URL-safe decoding
 */
function base64UrlDecode(str: string): string {
  // Add padding if needed
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) {
    base64 += '=';
  }
  return Buffer.from(base64, 'base64').toString('utf-8');
}

/**
 * Signs a message using HMAC SHA-256
 */
function sign(message: string, secret: string): string {
  return crypto
    .createHmac('sha256', secret)
    .update(message)
    .digest('base64url');
}

/**
 * Parses expiry string (e.g., '15m', '7d') to seconds
 */
function parseExpiry(expiry: string): number {
  const match = expiry.match(/^(\d+)([smhd])$/);
  if (!match) {
    throw new Error(`Invalid expiry format: ${expiry}`);
  }

  const value = parseInt(match[1]!, 10);
  const unit = match[2];

  switch (unit) {
    case 's':
      return value;
    case 'm':
      return value * 60;
    case 'h':
      return value * 60 * 60;
    case 'd':
      return value * 60 * 60 * 24;
    default:
      throw new Error(`Invalid expiry unit: ${unit}`);
  }
}
