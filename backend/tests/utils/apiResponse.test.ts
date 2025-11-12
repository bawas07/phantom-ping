import { describe, test, expect } from 'bun:test';
import { Hono } from 'hono';
import { successResponse, errorResponse, ApiError } from '@/utils/apiResponse';

describe('API Response Utilities', () => {
  let app: Hono;

  describe('successResponse', () => {
    test('should create success response with default status code', async () => {
      app = new Hono();
      app.get('/test', (c) => successResponse(c, 'Operation successful', { id: '123' }));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(200);
      expect(data.status).toBe(true);
      expect(data.message).toBe('Operation successful');
      expect(data.data.id).toBe('123');
    });

    test('should create success response with custom status code', async () => {
      app = new Hono();
      app.post('/test', (c) => successResponse(c, 'Resource created', { id: '456' }, 201));

      const res = await app.request('/test', { method: 'POST' });
      const data = await res.json() as any;

      expect(res.status).toBe(201);
      expect(data.status).toBe(true);
      expect(data.message).toBe('Resource created');
    });

    test('should handle empty data object', async () => {
      app = new Hono();
      app.get('/test', (c) => successResponse(c, 'Success'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(200);
      expect(data.status).toBe(true);
      expect(data.data).toEqual({});
    });
  });

  describe('errorResponse', () => {
    test('should create error response with code', async () => {
      app = new Hono();
      app.get('/test', (c) => errorResponse(c, 'Not found', 'RESOURCE_NOT_FOUND', 404));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(404);
      expect(data.status).toBe(false);
      expect(data.message).toBe('Not found');
      expect(data.data.code).toBe('RESOURCE_NOT_FOUND');
    });

    test('should include optional details', async () => {
      app = new Hono();
      app.get('/test', (c) => 
        errorResponse(c, 'Validation failed', 'INVALID_INPUT', 400, { field: 'email' })
      );

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(400);
      expect(data.data.code).toBe('INVALID_INPUT');
      expect(data.data.details).toEqual({ field: 'email' });
    });
  });

  describe('ApiError helpers', () => {
    test('badRequest should return 400', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.badRequest(c, 'Invalid input'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(400);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('INVALID_INPUT');
    });

    test('unauthorized should return 401 with default code', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.unauthorized(c, 'Authentication required'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(401);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_UNAUTHORIZED');
    });

    test('unauthorized should accept custom code', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.unauthorized(c, 'Token expired', 'AUTH_TOKEN_EXPIRED'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(401);
      expect(data.data.code).toBe('AUTH_TOKEN_EXPIRED');
    });

    test('forbidden should return 403', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.forbidden(c, 'Access denied'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(403);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('AUTH_FORBIDDEN');
    });

    test('notFound should return 404', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.notFound(c, 'User not found', 'USER_NOT_FOUND'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(404);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('USER_NOT_FOUND');
    });

    test('conflict should return 409', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.conflict(c, 'Resource already exists', 'RESOURCE_EXISTS'));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(409);
      expect(data.status).toBe(false);
      expect(data.data.code).toBe('RESOURCE_EXISTS');
    });

    test('serverError should return 500', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.serverError(c));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(res.status).toBe(500);
      expect(data.status).toBe(false);
      expect(data.message).toBe('An unexpected error occurred');
      expect(data.data.code).toBe('SERVER_ERROR');
    });

    test('should support details in all error helpers', async () => {
      app = new Hono();
      app.get('/test', (c) => ApiError.badRequest(c, 'Invalid email', { field: 'email', value: 'invalid' }));

      const res = await app.request('/test');
      const data = await res.json() as any;

      expect(data.data.details).toEqual({ field: 'email', value: 'invalid' });
    });
  });
});
