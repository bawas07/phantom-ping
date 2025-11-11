# Middleware

This directory contains middleware for the Phantom Ping backend, including authentication and authorization.

## Auth Middleware

The `authMiddleware` provides JWT-based authentication for protected routes.

### Usage

```typescript
import { Hono } from 'hono';
import { authMiddleware, getAuthUser } from '@/middleware';

const app = new Hono();

// Apply to all routes under /api/protected
app.use('/api/protected/*', authMiddleware);

// Use in route handlers
app.get('/api/protected/profile', (c) => {
  const user = getAuthUser(c);
  
  return c.json({
    userId: user.userId,
    organizationId: user.organizationId,
    role: user.role,
    supervisorTopicId: user.supervisorTopicId,
  });
});
```

### Features

- **JWT Verification**: Validates access tokens from the `Authorization` header
- **Token Expiration Handling**: Returns specific error codes for expired tokens
- **User Context**: Attaches decoded user information to the request context
- **Type Safety**: Provides TypeScript types for authenticated user data

### Error Responses

The middleware returns the following error codes:

- `AUTH_UNAUTHORIZED`: Missing or malformed Authorization header
- `AUTH_TOKEN_EXPIRED`: Access token has expired (client should refresh)
- `AUTH_INVALID_TOKEN`: Invalid token signature or format
- `SERVER_ERROR`: Unexpected server error

### Example Error Response

```json
{
  "error": {
    "code": "AUTH_TOKEN_EXPIRED",
    "message": "Access token has expired. Please refresh your token."
  }
}
```

### Helper Functions

#### `getAuthUser(c: Context): JWTPayload`

Retrieves the authenticated user from the request context. Use this in route handlers after applying `authMiddleware`.

```typescript
const user = getAuthUser(c);
console.log(user.userId, user.role);
```

### Requirements Satisfied

- **9.2**: JWT token verification with 15-minute expiration for access tokens
- **9.3**: Handle token expiration errors with appropriate error codes


---

## Authorization Middleware

The `authorize` middleware provides role-based access control, organization membership verification, and topic permission verification for protected routes.

### Usage

```typescript
import { Hono } from 'hono';
import { authMiddleware } from '@/middleware';
import { 
  authorize,
  requireOwner,
  requireOwnerOrAdmin,
  requireOwnerAdminOrSupervisor,
  requireOrganizationMembership,
  requireTopicPermission
} from '@/middleware';

const app = new Hono();

// Must be used after authMiddleware
app.use('/api/*', authMiddleware);

// Owner-only route
app.delete('/api/organizations/:orgId', requireOwner, (c) => {
  // Only owners can access this
});

// Owner or Admin route
app.post('/api/organizations/:orgId/users', requireOwnerOrAdmin, (c) => {
  // Owners and Admins can access this
});

// Verify organization membership
app.get('/api/organizations/:orgId/data', 
  requireOrganizationMembership, 
  (c) => {
    // User must belong to the organization in the route
  }
);

// Verify topic permissions (supervisors can only access their assigned topic)
app.get('/api/organizations/:orgId/topics/:topicId/messages',
  requireTopicPermission,
  (c) => {
    // Supervisors can only access their assigned topic
    // Owners/Admins can access any topic in their organization
  }
);

// Custom authorization with multiple checks
app.post('/api/organizations/:orgId/topics/:topicId/broadcast',
  authorize({
    roles: ['owner', 'admin', 'supervisor'],
    verifyOrganization: true,
    verifyTopicPermission: true
  }),
  (c) => {
    // Combined role, organization, and topic checks
  }
);
```

### Features

- **Role-Based Access Control**: Restrict routes to specific user roles (Owner, Admin, Supervisor, Normal)
- **Organization Membership Verification**: Ensure users can only access resources in their organization
- **Topic Permission Verification**: Enforce that supervisors can only access their assigned topic
- **Flexible Combinations**: Combine multiple authorization checks in a single middleware
- **Convenience Functions**: Pre-configured middleware for common authorization patterns

### Authorization Options

```typescript
interface AuthorizationOptions {
  // Required roles to access the route
  roles?: UserRole[];
  
  // Verify user belongs to organization in route params
  verifyOrganization?: boolean;
  
  // Verify topic permissions (supervisors only access assigned topic)
  verifyTopicPermission?: boolean;
}
```

### Convenience Middleware

- **`requireOwner`**: Only owners can access
- **`requireOwnerOrAdmin`**: Owners and admins can access
- **`requireOwnerAdminOrSupervisor`**: Owners, admins, and supervisors can access
- **`requireOrganizationMembership`**: User must belong to the organization in `:orgId` param
- **`requireTopicPermission`**: Enforces topic access rules (supervisors limited to assigned topic)

### Error Responses

The middleware returns the following error codes:

- `AUTH_FORBIDDEN`: User lacks required permissions or role
- `INVALID_INPUT`: Missing required route parameters (orgId or topicId)
- `TOPIC_NOT_FOUND`: Topic does not exist
- `SERVER_ERROR`: Unexpected server error

### Example Error Response

```json
{
  "error": {
    "code": "AUTH_FORBIDDEN",
    "message": "Access denied. Required role: owner or admin"
  }
}
```

### Authorization Logic

#### Role-Based Access
- Checks if user's role is in the allowed roles list
- Returns 403 if role is not permitted

#### Organization Membership
- Extracts `orgId` from route parameters
- Compares with user's `organizationId` from JWT token
- Returns 403 if user doesn't belong to the organization

#### Topic Permissions
- Extracts `topicId` from route parameters
- **For Supervisors**: Verifies the topic matches their `supervisorTopicId`
- **For Owners/Admins**: Verifies the topic belongs to their organization (queries database)
- Returns 403 if permissions are insufficient
- Returns 404 if topic doesn't exist

### Requirements Satisfied

- **3.1**: Role-based permission checking (Owner, Admin, Supervisor, Normal)
- **3.2**: Organization membership verification
- **4.1**: Permission verification for user management operations
- **5.1.1**: Topic permission verification for Supervisors
- **7.1**: Authorization for broadcast message operations
- **8.1**: Supervisor-specific topic access restrictions
