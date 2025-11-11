import { describe, test, expect } from 'bun:test';
import {
  hashPIN,
  verifyPIN,
  generateAccessToken,
  generateRefreshToken,
  verifyToken,
  generateRefreshTokenString,
  hashRefreshToken,
} from '@/utils/auth';

describe('PIN Hashing', () => {
  test('should hash a PIN using SHA-256', () => {
    const pin = '123456';
    const hash = hashPIN(pin);
    
    expect(hash).toBeDefined();
    expect(hash.length).toBe(64); // SHA-256 produces 64 hex characters
    expect(hash).toMatch(/^[a-f0-9]{64}$/);
  });

  test('should produce consistent hashes for the same PIN', () => {
    const pin = '123456';
    const hash1 = hashPIN(pin);
    const hash2 = hashPIN(pin);
    
    expect(hash1).toBe(hash2);
  });

  test('should produce different hashes for different PINs', () => {
    const pin1 = '123456';
    const pin2 = '654321';
    const hash1 = hashPIN(pin1);
    const hash2 = hashPIN(pin2);
    
    expect(hash1).not.toBe(hash2);
  });

  test('should verify correct PIN', () => {
    const pin = '123456';
    const hash = hashPIN(pin);
    
    expect(verifyPIN(pin, hash)).toBe(true);
  });

  test('should reject incorrect PIN', () => {
    const pin = '123456';
    const wrongPin = '654321';
    const hash = hashPIN(pin);
    
    expect(verifyPIN(wrongPin, hash)).toBe(false);
  });
});

describe('JWT Token Generation', () => {
  test('should generate access token with correct structure', () => {
    const token = generateAccessToken('user-123', 'org-abc', 'normal');
    
    expect(token).toBeDefined();
    const parts = token.split('.');
    expect(parts.length).toBe(3); // header.payload.signature
  });

  test('should generate refresh token with correct structure', () => {
    const token = generateRefreshToken('user-123', 'org-abc', 'admin');
    
    expect(token).toBeDefined();
    const parts = token.split('.');
    expect(parts.length).toBe(3);
  });

  test('should include supervisor topic ID in token when provided', () => {
    const token = generateAccessToken('user-123', 'org-abc', 'supervisor', 'topic-xyz');
    const decoded = verifyToken(token);
    
    expect(decoded.supervisorTopicId).toBe('topic-xyz');
  });

  test('should generate different tokens for different users', () => {
    const token1 = generateAccessToken('user-123', 'org-abc', 'normal');
    const token2 = generateAccessToken('user-456', 'org-abc', 'normal');
    
    expect(token1).not.toBe(token2);
  });
});

describe('JWT Token Verification', () => {
  test('should verify and decode valid access token', () => {
    const userId = 'user-123';
    const organizationId = 'org-abc';
    const role = 'admin';
    
    const token = generateAccessToken(userId, organizationId, role);
    const decoded = verifyToken(token);
    
    expect(decoded.userId).toBe(userId);
    expect(decoded.organizationId).toBe(organizationId);
    expect(decoded.role).toBe(role);
    expect(decoded.type).toBe('access');
  });

  test('should verify and decode valid refresh token', () => {
    const userId = 'user-456';
    const organizationId = 'org-xyz';
    const role = 'owner';
    
    const token = generateRefreshToken(userId, organizationId, role);
    const decoded = verifyToken(token);
    
    expect(decoded.userId).toBe(userId);
    expect(decoded.organizationId).toBe(organizationId);
    expect(decoded.role).toBe(role);
    expect(decoded.type).toBe('refresh');
  });

  test('should throw error for invalid token format', () => {
    expect(() => verifyToken('invalid-token')).toThrow('Invalid token format');
  });

  test('should throw error for tampered token', () => {
    const token = generateAccessToken('user-123', 'org-abc', 'normal');
    const parts = token.split('.');
    const tamperedToken = `${parts[0]}.${parts[1]}.invalid-signature`;
    
    expect(() => verifyToken(tamperedToken)).toThrow('Invalid token signature');
  });
});

describe('Refresh Token String Generation', () => {
  test('should generate random refresh token string', () => {
    const token = generateRefreshTokenString();
    
    expect(token).toBeDefined();
    expect(token.length).toBe(64); // 32 bytes = 64 hex characters
    expect(token).toMatch(/^[a-f0-9]{64}$/);
  });

  test('should generate unique tokens', () => {
    const token1 = generateRefreshTokenString();
    const token2 = generateRefreshTokenString();
    
    expect(token1).not.toBe(token2);
  });

  test('should hash refresh token', () => {
    const token = generateRefreshTokenString();
    const hash = hashRefreshToken(token);
    
    expect(hash).toBeDefined();
    expect(hash.length).toBe(64); // SHA-256 produces 64 hex characters
    expect(hash).toMatch(/^[a-f0-9]{64}$/);
  });

  test('should produce consistent hashes for same token', () => {
    const token = generateRefreshTokenString();
    const hash1 = hashRefreshToken(token);
    const hash2 = hashRefreshToken(token);
    
    expect(hash1).toBe(hash2);
  });
});
