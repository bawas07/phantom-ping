import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { authMiddleware } from '@/middleware/auth';
import { 
  authorize, 
  requireOwner, 
  requireOwnerOrAdmin,
  requireOwnerAdminOrSupervisor,
  requireOrganizationMembership,
  requireTopicPermission
} from '@/middleware/authorization';
import { generateAccessToken } from '@/utils/auth';
import { getDatabase, closeDatabase, execute } from '@/db';

describe('Authorization Middleware', () => {
  let app: Hono;

  beforeEach(() => {
    // Initialize database and create test data
    const db = getDatabase();
    
    // Create test organization
    execute(
      'INSERT INTO organizations (id, name, owner_id) VALUES (?, ?, ?)',
      ['test-org', 'Test Organization', 'owner-123']
    );
    
    // Create test topics
    execute(
      'INSERT INTO topics (id, organization_id, name) VALUES (?, ?, ?)',
      ['topic-123', 'test-org', 'Test Topic']
    );
    
    execute(
      'INSERT INTO topics (id, organization_id, name) VALUES (?, ?, ?)',
      ['topic-456', 'test-org', 'Another Topic']
    );
    
    // Create another organization for cross-org tests
    execute(
      'INSERT INTO organizations (id, name, owner_id) VALUES (?, ?, ?)',
      ['other-org', 'Other Organization', 'owner-999']
    );
    
    execute(
      'INSERT INTO topics (id, organization_id, name) VALUES (?, ?, ?)',
      ['topic-999', 'other-org', 'Other Org Topic']
    );

    app = new Hono();
    
    // Test routes with different authorization requirements
    app.use('/api/*', authMiddleware);
    
    app.get('/api/owner-only', requireOwner, (c) => {
      return c.json({ success: true, message: 'Owner access granted' });
    });
    
    app.get('/api/owner-or-admin', requireOwnerOrAdmin, (c) => {
      return c.json({ success: true, message: 'Owner or Admin access granted' });
    });
    
    app.get('/api/owner-admin-supervisor', requireOwnerAdminOrSupervisor, (c) => {
      return c.json({ success: true, message: 'Owner, Admin, or Supervisor access granted' });
    });
    
    app.get('/api/organizations/:orgId/data', requireOrganizationMembership, (c) => {
      return c.json({ success: true, message: 'Organization member access granted' });
    });
    
    app.get('/api/organizations/:orgId/topics/:topicId/data', requireTopicPermission, (c) => {
      return c.json({ success: true, message: 'Topic access granted' });
    });
    
    app.get('/api/custom', authorize({ roles: ['admin', 'supervisor'] }), (c) => {
      return c.json({ success: true, message: 'Custom authorization passed' });
    });
    
    app.get('/api/organizations/:orgId/topics/:topicId/combined',
      authorize({ 
        roles: ['owner', 'admin', 'supervisor'],
        verifyOrganization: true,
        verifyTopicPermission: true
      }),
      (c) => {
        return c.json({ success: true, message: 'Combined authorization passed' });
      }
    );
  });

  afterEach(() => {
    // Clean up test data
    execute('DELETE FROM topics WHERE organization_id IN (?, ?)', ['test-org', 'other-org']);
    execute('DELETE FROM organizations WHERE id IN (?, ?)', ['test-org', 'other-org']);
  });

  describe('Role-Based Authorization', () => {
    test('should allow owner to access owner-only route', async () => {
      const token = generateAccessToken('owner-123', 'test-org', 'owner');
      
      const req = new Request('http://localhost/api/owner-only', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should deny admin access to owner-only route', async () => {
      const token = generateAccessToken('admin-123', 'test-org', 'admin');
      
      const req = new Request('http://localhost/api/owner-only', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
    });

    test('should allow owner to access owner-or-admin route', async () => {
      const token = generateAccessToken('owner-123', 'test-org', 'owner');
      
      const req = new Request('http://localhost/api/owner-or-admin', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should allow admin to access owner-or-admin route', async () => {
      const token = generateAccessToken('admin-123', 'test-org', 'admin');
      
      const req = new Request('http://localhost/api/owner-or-admin', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should deny supervisor access to owner-or-admin route', async () => {
      const token = generateAccessToken('supervisor-123', 'test-org', 'supervisor', 'topic-123');
      
      const req = new Request('http://localhost/api/owner-or-admin', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
    });

    test('should allow all privileged roles to access owner-admin-supervisor route', async () => {
      const roles = [
        { role: 'owner' as const, userId: 'owner-123' },
        { role: 'admin' as const, userId: 'admin-123' },
        { role: 'supervisor' as const, userId: 'supervisor-123', topicId: 'topic-123' },
      ];
      
      for (const { role, userId, topicId } of roles) {
        const token = generateAccessToken(userId, 'test-org', role, topicId);
        
        const req = new Request('http://localhost/api/owner-admin-supervisor', {
          headers: { Authorization: `Bearer ${token}` },
        });
        
        const res = await app.fetch(req);
        const data = await res.json() as any;
        
        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });

    test('should deny normal user access to privileged route', async () => {
      const token = generateAccessToken('user-123', 'test-org', 'normal');
      
      const req = new Request('http://localhost/api/owner-admin-supervisor', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
    });

    test('should support custom role combinations', async () => {
      const adminToken = generateAccessToken('admin-123', 'test-org', 'admin');
      const supervisorToken = generateAccessToken('supervisor-123', 'test-org', 'supervisor', 'topic-123');
      const ownerToken = generateAccessToken('owner-123', 'test-org', 'owner');
      
      // Admin should pass
      let req = new Request('http://localhost/api/custom', {
        headers: { Authorization: `Bearer ${adminToken}` },
      });
      let res = await app.fetch(req);
      expect(res.status).toBe(200);
      
      // Supervisor should pass
      req = new Request('http://localhost/api/custom', {
        headers: { Authorization: `Bearer ${supervisorToken}` },
      });
      res = await app.fetch(req);
      expect(res.status).toBe(200);
      
      // Owner should fail (not in allowed roles)
      req = new Request('http://localhost/api/custom', {
        headers: { Authorization: `Bearer ${ownerToken}` },
      });
      res = await app.fetch(req);
      expect(res.status).toBe(403);
    });
  });

  describe('Organization Membership Verification', () => {
    test('should allow access when user belongs to organization', async () => {
      const token = generateAccessToken('user-123', 'test-org', 'normal');
      
      const req = new Request('http://localhost/api/organizations/test-org/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should deny access when user does not belong to organization', async () => {
      const token = generateAccessToken('user-123', 'test-org', 'normal');
      
      const req = new Request('http://localhost/api/organizations/other-org/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
      expect(data.error.message).toContain('do not belong to this organization');
    });

    test('should return error when orgId is missing from route', async () => {
      const token = generateAccessToken('user-123', 'test-org', 'normal');
      
      // Create a route without orgId param
      const testApp = new Hono();
      testApp.use('/api/*', authMiddleware);
      testApp.get('/api/no-org-param', requireOrganizationMembership, (c) => {
        return c.json({ success: true });
      });
      
      const req = new Request('http://localhost/api/no-org-param', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await testApp.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(400);
      expect(data.error.code).toBe('INVALID_INPUT');
    });
  });

  describe('Topic Permission Verification', () => {
    test('should allow supervisor to access their assigned topic', async () => {
      const token = generateAccessToken('supervisor-123', 'test-org', 'supervisor', 'topic-123');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-123/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should deny supervisor access to different topic', async () => {
      const token = generateAccessToken('supervisor-123', 'test-org', 'supervisor', 'topic-123');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-456/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
      expect(data.error.message).toContain('can only access their assigned topic');
    });

    test('should deny supervisor without assigned topic', async () => {
      const token = generateAccessToken('supervisor-123', 'test-org', 'supervisor');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-123/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
      expect(data.error.message).toContain('does not have an assigned topic');
    });

    test('should allow owner to access any topic in their organization', async () => {
      const token = generateAccessToken('owner-123', 'test-org', 'owner');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-123/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should allow admin to access any topic in their organization', async () => {
      const token = generateAccessToken('admin-123', 'test-org', 'admin');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-456/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should deny owner access to topic from different organization', async () => {
      const token = generateAccessToken('owner-123', 'test-org', 'owner');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-999/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
      expect(data.error.message).toContain('does not belong to your organization');
    });

    test('should return error for non-existent topic', async () => {
      const token = generateAccessToken('owner-123', 'test-org', 'owner');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/non-existent/data', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(404);
      expect(data.error.code).toBe('TOPIC_NOT_FOUND');
    });

    test('should return error when topicId is missing from route', async () => {
      const token = generateAccessToken('owner-123', 'test-org', 'owner');
      
      // Create a route without topicId param
      const testApp = new Hono();
      testApp.use('/api/*', authMiddleware);
      testApp.get('/api/no-topic-param', requireTopicPermission, (c) => {
        return c.json({ success: true });
      });
      
      const req = new Request('http://localhost/api/no-topic-param', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await testApp.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(400);
      expect(data.error.code).toBe('INVALID_INPUT');
    });
  });

  describe('Combined Authorization', () => {
    test('should pass all checks when user has correct role, org, and topic', async () => {
      const token = generateAccessToken('supervisor-123', 'test-org', 'supervisor', 'topic-123');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-123/combined', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
    });

    test('should fail when role is correct but organization is wrong', async () => {
      const token = generateAccessToken('admin-123', 'test-org', 'admin');
      
      const req = new Request('http://localhost/api/organizations/other-org/topics/topic-999/combined', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
    });

    test('should fail when supervisor tries to access wrong topic', async () => {
      const token = generateAccessToken('supervisor-123', 'test-org', 'supervisor', 'topic-123');
      
      const req = new Request('http://localhost/api/organizations/test-org/topics/topic-456/combined', {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const res = await app.fetch(req);
      const data = await res.json() as any;
      
      expect(res.status).toBe(403);
      expect(data.error.code).toBe('AUTH_FORBIDDEN');
    });
  });
});
