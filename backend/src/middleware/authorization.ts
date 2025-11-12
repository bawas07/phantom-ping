import type { Context, Next } from 'hono';
import { getAuthUser } from './auth';
import { queryOne } from '@/db';

/**
 * User role type
 */
export type UserRole = 'owner' | 'admin' | 'supervisor' | 'normal';

/**
 * Authorization options for role-based access control
 */
export interface AuthorizationOptions {
  /**
   * Required roles to access the route
   * If empty or undefined, any authenticated user can access
   */
  roles?: UserRole[];
  
  /**
   * Whether to verify organization membership
   * If true, checks that the user belongs to the organization specified in the route params
   */
  verifyOrganization?: boolean;
  
  /**
   * Whether to verify topic permissions for supervisors
   * If true, checks that supervisors can only access their assigned topic
   */
  verifyTopicPermission?: boolean;
}

/**
 * Creates an authorization middleware with specified options
 * Must be used after authMiddleware to ensure user is authenticated
 * 
 * Usage:
 * app.post('/api/organizations/:orgId/users', 
 *   authMiddleware, 
 *   authorize({ roles: ['owner', 'admin'], verifyOrganization: true }),
 *   handler
 * );
 * 
 * @param options - Authorization options
 * @returns Middleware function
 */
export function authorize(options: AuthorizationOptions = {}) {
  return async (c: Context, next: Next) => {
    try {
      const user = getAuthUser(c);
      
      // Check role-based permissions
      if (options.roles && options.roles.length > 0) {
        if (!options.roles.includes(user.role)) {
          return c.json(
            {
              status: false,
              message: `Access denied. Required role: ${options.roles.join(' or ')}`,
              data: {
                code: 'AUTH_FORBIDDEN',
              },
            },
            403
          );
        }
      }
      
      // Verify organization membership
      if (options.verifyOrganization) {
        const orgId = c.req.param('orgId');
        
        if (!orgId) {
          return c.json(
            {
              status: false,
              message: 'Organization ID is required in route parameters',
              data: {
                code: 'INVALID_INPUT',
              },
            },
            400
          );
        }
        
        // Check if user belongs to the organization
        if (user.organizationId !== orgId) {
          return c.json(
            {
              status: false,
              message: 'Access denied. You do not belong to this organization.',
              data: {
                code: 'AUTH_FORBIDDEN',
              },
            },
            403
          );
        }
      }
      
      // Verify topic permissions for supervisors
      if (options.verifyTopicPermission) {
        const topicId = c.req.param('topicId');
        
        if (!topicId) {
          return c.json(
            {
              status: false,
              message: 'Topic ID is required in route parameters',
              data: {
                code: 'INVALID_INPUT',
              },
            },
            400
          );
        }
        
        // If user is a supervisor, verify they can only access their assigned topic
        if (user.role === 'supervisor') {
          if (!user.supervisorTopicId) {
            return c.json(
              {
                status: false,
                message: 'Supervisor does not have an assigned topic',
                data: {
                  code: 'AUTH_FORBIDDEN',
                },
              },
              403
            );
          }
          
          if (user.supervisorTopicId !== topicId) {
            return c.json(
              {
                status: false,
                message: 'Access denied. Supervisors can only access their assigned topic.',
                data: {
                  code: 'AUTH_FORBIDDEN',
                },
              },
              403
            );
          }
        }
        
        // For non-supervisors (owner, admin), verify the topic belongs to their organization
        if (user.role !== 'supervisor') {
          const topic = queryOne<{ organization_id: string }>(
            'SELECT organization_id FROM topics WHERE id = ?',
            [topicId]
          );
          
          if (!topic) {
            return c.json(
              {
                status: false,
                message: 'Topic not found',
                data: {
                  code: 'TOPIC_NOT_FOUND',
                },
              },
              404
            );
          }
          
          if (topic.organization_id !== user.organizationId) {
            return c.json(
              {
                status: false,
                message: 'Access denied. Topic does not belong to your organization.',
                data: {
                  code: 'AUTH_FORBIDDEN',
                },
              },
              403
            );
          }
        }
      }
      
      await next();
    } catch (error) {
      // Handle unexpected errors
      return c.json(
        {
          status: false,
          message: 'An unexpected error occurred during authorization',
          data: {
            code: 'SERVER_ERROR',
          },
        },
        500
      );
    }
  };
}

/**
 * Convenience middleware for owner-only routes
 */
export const requireOwner = authorize({ roles: ['owner'] });

/**
 * Convenience middleware for owner or admin routes
 */
export const requireOwnerOrAdmin = authorize({ roles: ['owner', 'admin'] });

/**
 * Convenience middleware for owner, admin, or supervisor routes
 */
export const requireOwnerAdminOrSupervisor = authorize({ 
  roles: ['owner', 'admin', 'supervisor'] 
});

/**
 * Convenience middleware for organization membership verification
 */
export const requireOrganizationMembership = authorize({ 
  verifyOrganization: true 
});

/**
 * Convenience middleware for topic permission verification
 */
export const requireTopicPermission = authorize({ 
  verifyTopicPermission: true 
});
