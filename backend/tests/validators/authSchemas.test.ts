import { describe, test, expect } from 'bun:test';
import { loginSchema, refreshTokenSchema, logoutSchema } from '@/validators/authSchemas';

describe('Auth Validation Schemas', () => {
  describe('loginSchema', () => {
    test('should validate valid login data', () => {
      const validData = {
        pin: '123456',
        organizationId: 'TEST-ORG',
      };

      const result = loginSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.pin).toBe('123456');
        expect(result.data.organizationId).toBe('TEST-ORG');
      }
    });

    test('should trim whitespace from inputs', () => {
      const dataWithWhitespace = {
        pin: '  123456  ',
        organizationId: '  TEST-ORG  ',
      };

      const result = loginSchema.safeParse(dataWithWhitespace);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.pin).toBe('123456');
        expect(result.data.organizationId).toBe('TEST-ORG');
      }
    });

    test('should reject missing PIN', () => {
      const invalidData = {
        organizationId: 'TEST-ORG',
      };

      const result = loginSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.length).toBeGreaterThan(0);
        expect(result.error.issues[0]?.path).toContain('pin');
      }
    });

    test('should reject empty PIN', () => {
      const invalidData = {
        pin: '',
        organizationId: 'TEST-ORG',
      };

      const result = loginSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0]?.message).toBe('PIN is required');
      }
    });

    test('should reject missing organization ID', () => {
      const invalidData = {
        pin: '123456',
      };

      const result = loginSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.length).toBeGreaterThan(0);
        expect(result.error.issues[0]?.path).toContain('organizationId');
      }
    });

    test('should reject empty organization ID', () => {
      const invalidData = {
        pin: '123456',
        organizationId: '',
      };

      const result = loginSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0]?.message).toBe('Organization ID is required');
      }
    });

    test('should reject organization ID longer than 15 characters', () => {
      const invalidData = {
        pin: '123456',
        organizationId: 'THIS-IS-TOO-LONG-ORG-ID',
      };

      const result = loginSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0]?.message).toContain('15 characters or less');
      }
    });
  });

  describe('refreshTokenSchema', () => {
    test('should validate valid refresh token', () => {
      const validData = {
        refreshToken: 'valid-refresh-token-string',
      };

      const result = refreshTokenSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.refreshToken).toBe('valid-refresh-token-string');
      }
    });

    test('should trim whitespace from refresh token', () => {
      const dataWithWhitespace = {
        refreshToken: '  valid-refresh-token-string  ',
      };

      const result = refreshTokenSchema.safeParse(dataWithWhitespace);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.refreshToken).toBe('valid-refresh-token-string');
      }
    });

    test('should reject missing refresh token', () => {
      const invalidData = {};

      const result = refreshTokenSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.length).toBeGreaterThan(0);
        expect(result.error.issues[0]?.path).toContain('refreshToken');
      }
    });

    test('should reject empty refresh token', () => {
      const invalidData = {
        refreshToken: '',
      };

      const result = refreshTokenSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0]?.message).toBe('Refresh token is required');
      }
    });
  });

  describe('logoutSchema', () => {
    test('should validate valid logout data', () => {
      const validData = {
        refreshToken: 'valid-refresh-token-string',
      };

      const result = logoutSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.refreshToken).toBe('valid-refresh-token-string');
      }
    });

    test('should trim whitespace from refresh token', () => {
      const dataWithWhitespace = {
        refreshToken: '  valid-refresh-token-string  ',
      };

      const result = logoutSchema.safeParse(dataWithWhitespace);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.refreshToken).toBe('valid-refresh-token-string');
      }
    });

    test('should reject missing refresh token', () => {
      const invalidData = {};

      const result = logoutSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.length).toBeGreaterThan(0);
        expect(result.error.issues[0]?.path).toContain('refreshToken');
      }
    });

    test('should reject empty refresh token', () => {
      const invalidData = {
        refreshToken: '',
      };

      const result = logoutSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0]?.message).toBe('Refresh token is required');
      }
    });
  });
});
