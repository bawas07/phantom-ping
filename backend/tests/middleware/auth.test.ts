import { describe, test, expect, beforeEach } from 'bun:test';
import { Hono } from 'hono';
import { authMiddleware, getAuthUser } from '@/middleware/auth';
import { generateAccessToken, generateRefreshToken } from '@/utils/auth';

describe('Authentication Middleware', () => {
  let app: Hono;

  beforeEach(() => {
    app = new Hono();
    
    // Protected route that uses auth middleware
    app.use('/api/protected/*', authMiddleware);
    app.get('/api/protected/test', (c) => {
      const user = getAuthUser(c);
      return c.json({ success: true, user });
    });
    
    // Public route for comparison
    app.get('/api/public/test', (c) => {
      return c.json({ success: true, public: true });
    });
  });

  describe('Valid Token', () => {
    test('should allow access with valid access token', async () => {
      const token = generateAccessToken('user-123', 'org-abc', 'normal');
      
      const req = new Request('http://localhost/api/protected/test', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.user.userId).toBe('user-123');
      expect(data.user.organizationId).toBe('org-abc');
      expect(data.user.role).toBe('normal');
      expect(data.user.type).toBe('access');
    });

    test('should extract supervisor topic ID from token', async () => {
      const token = generateAccessToken('user-456', 'org-xyz', 'supervisor', 'topic-789');
      
      const req = new Request('http://localhost/api/protected/test', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.user.supervisorTopicId).toBe('topic-789');
    });

    test('should work with different roles', async () => {
      const roles = ['owner', 'admin', 'supervisor', 'normal'] as const;
      
      for (const role of roles) {
        const token = generateAccessToken('user-123', 'org-abc', role);
        
        const req = new Request('http://localhost/api/protected/test', {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
        
        const res = await app.fetch(req);
        const data = await res.json() as any;
        
        expect(res.status).toBe(200);
        expect(data.user.role).toBe(role);
      }
    });
  });

  describe('Missing Authorization', () => {
    test('should reject request without Authorization header', async () => {
      const req = new Request('http://localhost/api/protected/test');
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(401);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_UNAUTHORIZED');
      expect(data.message).toContain('Missing authorization header');
    });
  });

  describe('Invalid Authorization Format', () => {
    test('should reject malformed Authorization header', async () => {
      const req = new Request('http://localhost/api/protected/test', {
        headers: {
          Authorization: 'InvalidFormat',
        },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(401);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_UNAUTHORIZED');
      expect(data.message).toContain('Invalid authorization header format');
    });

    test('should reject non-Bearer token', async () => {
      const token = generateAccessToken('user-123', 'org-abc', 'normal');
      
      const req = new Request('http://localhost/api/protected/test', {
        headers: {
          Authorization: `Basic ${token}`,
        },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(401);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_UNAUTHORIZED');
    });
  });

  describe('Invalid Token', () => {
    test('should reject invalid token', async () => {
      const req = new Request('http://localhost/api/protected/test', {
        headers: {
          Authorization: 'Bearer invalid.token.here',
        },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(401);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_INVALID_TOKEN');
    });

    test('should reject refresh token on protected route', async () => {
      const refreshToken = generateRefreshToken('user-123', 'org-abc', 'normal');
      
      const req = new Request('http://localhost/api/protected/test', {
        headers: {
          Authorization: `Bearer ${refreshToken}`,
        },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(401);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_INVALID_TOKEN');
      expect(data.message).toContain('Access token required');
    });
  });

  describe('Public Routes', () => {
    test('should allow access to public routes without token', async () => {
      const req = new Request('http://localhost/api/public/test');
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.public).toBe(true);
    });
  });

  describe('getAuthUser Helper', () => {
    test('should throw error when user not in context', () => {
      const mockContext = {
        get: () => undefined,
      } as any;
      
      expect(() => getAuthUser(mockContext)).toThrow('User not authenticated');
    });
  });
});
