---
inclusion: fileMatch
fileMatchPattern: "backend/**/*.ts"
---

# Phantom Ping Backend Steering

## Project Overview

Phantom Ping is a real-time group pager system with a Bun/TypeScript backend. The system enables hierarchical organization management with Owner, Admin, Supervisor, and Normal User roles. Organizations can create topic-based sub-meshes for targeted messaging with three severity levels.

## Technology Stack

- **Runtime**: Bun with TypeScript
- **Web Framework**: Hono for routing and middleware
- **Database**: Bun's native SQLite (`bun:sqlite`) with parameterized queries
- **WebSocket**: Bun's native WebSocket API
- **Authentication**: JWT (15-minute access tokens) + refresh tokens (7-day expiration)
- **Password Hashing**: Bun's native SHA-256 hashing (`Bun.password.hash` with SHA-256)
- **Validation**: Zod for type-safe request validation
- **Logging**: Pino for structured JSON logging with HTTP and WebSocket middleware

## Code Organization

```
backend/
├── src/
│   ├── server.ts              # Main server entry point
│   ├── config/                # Configuration and environment
│   ├── db/                    # Database connection and migrations
│   ├── middleware/            # Auth, validation, error handling, logging
│   ├── services/              # Business logic (auth, org, topic, broadcast)
│   ├── routes/                # API route handlers
│   ├── validators/            # Zod validation schemas
│   ├── websocket/             # WebSocket server and handlers
│   ├── utils/                 # Utilities (ID generation, API responses)
│   └── logger.ts              # Pino logger configuration
├── tests/                     # Unit and integration tests
└── migrations/                # Database migration files
```

## Core Principles

### 1. ID Generation
- Use **UUIDv7** for all entity IDs except organization ID
- Organization IDs are **user-provided, max 15 characters**
- PINs are **unique within organization scope only** (can be reused across organizations)
- Generate PINs using a secure random number generator

### 2. Authentication & Authorization
- Hash all PINs with **Bun's native SHA-256** (`Bun.password.hash` with algorithm 'sha256') before storage
- Verify PINs using `Bun.password.verify` for constant-time comparison
- Issue **JWT access tokens** with 15-minute expiration
- Issue **refresh tokens** with 7-day expiration, stored in database
- Validate organization membership on all operations
- Enforce role-based permissions:
  - **Owner**: Promote/demote Admins, transfer ownership, all Admin privileges
  - **Admin**: Register users, promote/demote Supervisors, kick users, manage topics, broadcast org-wide or to topics
  - **Supervisor**: Broadcast only to assigned topic (one topic per supervisor)
  - **Normal User**: Receive and acknowledge messages only

### 3. Role Constraints
- **Mutually exclusive**: A user cannot be both Admin and Supervisor
- **One topic per Supervisor**: Each Supervisor is bound to exactly one topic via `supervisor_topic_id`
- **One Owner per organization**: Ownership transfer changes current Owner to Admin
- Admins can kick other Admins, but only Owner can demote Admins

### 4. Broadcasting Rules
- **Owner/Admin**: Can broadcast organization-wide or to specific topics
- **Supervisor**: Automatically broadcasts to assigned topic only (ignore scope/topicId parameters)
- Message payload must include: `level` (low/medium/high), `title`, `message`, optional `code`
- Deliver messages via WebSocket to all connected recipients
- Track acknowledgements in database

### 5. Database Schema
- Use the exact schema from design.md with all tables and indexes
- Enforce foreign key constraints
- Use `CHECK` constraints for enums (role, level, scope)
- Set `supervisor_topic_id` only when role is 'supervisor'
- Clear `supervisor_topic_id` when demoting Supervisor to Normal User

### 6. Error Handling & API Responses
- **Always use standardized response helpers** from `@/utils/apiResponse`
- Return structured responses with `status`, `message`, and `data` fields
- Use `successResponse()` for successful operations
- Use `ApiError` helpers for errors: `badRequest()`, `unauthorized()`, `forbidden()`, `notFound()`, `conflict()`, `serverError()`
- Error responses include `code`, `message`, and optional `details`
- Use specific error codes: `AUTH_INVALID_CREDENTIALS`, `AUTH_UNAUTHORIZED`, `AUTH_FORBIDDEN`, `ORG_NOT_FOUND`, `ORG_ID_TOO_LONG`, `ORG_ID_EXISTS`, `USER_NOT_FOUND`, `TOPIC_NOT_FOUND`, `ROLE_CONFLICT`, `PERMISSION_DENIED`, `INVALID_INPUT`, `SERVER_ERROR`
- Log all errors with stack traces using Pino
- Never expose sensitive information in error messages
- Include request ID in all error logs for traceability

### 7. WebSocket Management
- Use **Bun's native WebSocket API** with `Bun.serve` websocket handler
- Authenticate connections using JWT from query parameter or upgrade request headers
- Map user IDs to WebSocket connections (support multiple connections per user)
- Implement ping/pong using Bun's built-in `ws.ping()` and `pong` event
- Clean up disconnected connections in `close` handler
- Handle reconnection gracefully with connection state tracking
- Log all WebSocket events (open, close, message, error) with user context using Pino

### 8. Request Validation
- **Always use Zod schemas** for request validation (body and query parameters)
- Define schemas in `src/validators/` directory
- Use `validateBody()` and `validateQuery()` middleware
- Schemas automatically trim whitespace and provide type inference
- Validation errors return structured 400 responses with field-level details
- Never perform manual validation - use Zod schemas instead

### 9. Security Best Practices
- Use HTTPS/WSS in production
- Validate all inputs using Zod schemas
- Use parameterized queries to prevent SQL injection
- Rate limit login attempts and broadcast frequency
- Invalidate refresh tokens on logout
- Set appropriate CORS headers

### 10. API Endpoint Patterns

**Authentication Endpoints:**
- `POST /api/auth/login` - Validate PIN + Organization ID, return tokens
- `POST /api/auth/refresh` - Exchange refresh token for new tokens
- `POST /api/auth/logout` - Invalidate refresh token

**Organization Endpoints:**
- `POST /api/organizations` - Create organization (public)
- `POST /api/organizations/:orgId/users` - Register user (Admin/Owner)
- `PUT /api/organizations/:orgId/users/:userId/role` - Promote/demote (Owner for Admin, Admin for Supervisor)
- `DELETE /api/organizations/:orgId/users/:userId` - Kick user (Admin/Owner)
- `PUT /api/organizations/:orgId/ownership` - Transfer ownership (Owner only)

**Topic Endpoints:**
- `POST /api/organizations/:orgId/topics` - Create topic (Admin/Owner)
- `POST /api/organizations/:orgId/topics/:topicId/users` - Assign user to topic (Admin/Owner)
- `GET /api/organizations/:orgId/topics` - List topics (Admin/Owner)

**Broadcast Endpoints:**
- `POST /api/broadcast` - Send broadcast (Owner/Admin/Supervisor)
- `POST /api/messages/:messageId/acknowledge` - Acknowledge message (any user)
- `GET /api/messages/history` - Get message history (any user)

**WebSocket Events:**
- Server → Client: `message:broadcast` with payload
- Client → Server: `message:acknowledge` with messageId and userId

### 11. Testing Requirements
- Write unit tests for all services
- Test role-based permission logic thoroughly
- Test WebSocket message delivery
- Mock database for unit tests
- Use integration tests for API endpoints
- Test error scenarios and edge cases

### 12. Performance Considerations
- Use database connection pooling
- Add indexes on frequently queried columns (see schema)
- Batch WebSocket message delivery when possible
- Implement rate limiting on broadcast endpoints
- Clean up expired refresh tokens periodically

### 13. Validation Rules
- Organization ID: max 15 characters, alphanumeric
- Email: valid email format
- PIN: numeric, unique within organization
- Role: must be 'owner', 'admin', 'supervisor', or 'normal'
- Level: must be 'low', 'medium', or 'high'
- Scope: must be 'organization' or 'topic'
- Title and message: required, non-empty strings

## Common Patterns

### Pino Logger Setup
```typescript
import pino from 'pino';

// Create logger instance
export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'development' ? {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'HH:MM:ss Z',
      ignore: 'pid,hostname'
    }
  } : undefined,
  formatters: {
    level: (label) => {
      return { level: label };
    }
  },
  serializers: {
    req: (req) => ({
      method: req.method,
      url: req.url,
      headers: req.headers,
      remoteAddress: req.headers['x-forwarded-for'] || req.socket?.remoteAddress
    }),
    res: (res) => ({
      statusCode: res.statusCode
    }),
    err: pino.stdSerializers.err
  }
});

// Child logger for specific contexts
export const createChildLogger = (context: Record<string, any>) => {
  return logger.child(context);
};
```

### HTTP Logging Middleware (Hono)
```typescript
import { MiddlewareHandler } from 'hono';
import { logger } from '../logger';

export const httpLogger: MiddlewareHandler = async (c, next) => {
  const start = Date.now();
  const requestId = crypto.randomUUID();
  
  // Attach request ID to context
  c.set('requestId', requestId);
  
  // Log incoming request
  logger.info({
    requestId,
    method: c.req.method,
    path: c.req.path,
    query: c.req.query(),
    userAgent: c.req.header('user-agent')
  }, 'Incoming request');
  
  await next();
  
  const duration = Date.now() - start;
  
  // Log response
  logger.info({
    requestId,
    method: c.req.method,
    path: c.req.path,
    status: c.res.status,
    duration: `${duration}ms`
  }, 'Request completed');
};
```

### WebSocket Logging Pattern
```typescript
import { logger } from '../logger';

const wsLogger = logger.child({ component: 'websocket' });

Bun.serve({
  websocket: {
    open(ws) {
      const userId = ws.data.userId;
      const connectionId = crypto.randomUUID();
      ws.data.connectionId = connectionId;
      
      wsLogger.info({
        event: 'connection_open',
        userId,
        connectionId
      }, 'WebSocket connection opened');
      
      connectionMap.set(userId, ws);
    },
    message(ws, message) {
      const { userId, connectionId } = ws.data;
      
      try {
        const data = JSON.parse(message);
        wsLogger.debug({
          event: 'message_received',
          userId,
          connectionId,
          messageType: data.event
        }, 'WebSocket message received');
        
        // Handle message...
      } catch (error) {
        wsLogger.error({
          event: 'message_error',
          userId,
          connectionId,
          error
        }, 'Error processing WebSocket message');
      }
    },
    close(ws, code, reason) {
      const { userId, connectionId } = ws.data;
      
      wsLogger.info({
        event: 'connection_close',
        userId,
        connectionId,
        code,
        reason
      }, 'WebSocket connection closed');
      
      connectionMap.delete(userId);
    },
    error(ws, error) {
      const { userId, connectionId } = ws.data;
      
      wsLogger.error({
        event: 'connection_error',
        userId,
        connectionId,
        error
      }, 'WebSocket error occurred');
    }
  }
});
```

### Service Layer Logging Pattern
```typescript
import { logger } from '../logger';

class BroadcastService {
  private logger = logger.child({ service: 'broadcast' });
  
  async sendBroadcast(senderId: string, payload: BroadcastPayload) {
    this.logger.info({
      senderId,
      level: payload.level,
      scope: payload.scope,
      topicId: payload.topicId
    }, 'Broadcasting message');
    
    try {
      // 1. Validate sender permissions
      // 2. Determine recipients
      const recipients = await this.getRecipients(payload);
      
      this.logger.debug({
        senderId,
        recipientCount: recipients.length
      }, 'Recipients determined');
      
      // 3. Store message in database
      // 4. Deliver via WebSocket
      // 5. Return result
      
      this.logger.info({
        senderId,
        recipientCount: recipients.length
      }, 'Broadcast completed successfully');
      
      return { success: true, recipientCount: recipients.length };
    } catch (error) {
      this.logger.error({
        senderId,
        error
      }, 'Broadcast failed');
      throw error;
    }
  }
}
```

### Hono Middleware Chain
```typescript
import { Hono } from 'hono';

const app = new Hono();

// Apply HTTP logging middleware globally
app.use('*', httpLogger);

// Protected route example with Hono
app.post('/api/broadcast', 
  authenticateJWT,           // Verify JWT and attach user to context
  requireRole(['owner', 'admin', 'supervisor']),  // Check role
  validateBroadcastInput,    // Validate request body
  async (c) => {
    const user = c.get('user');
    const requestId = c.get('requestId');
    
    // Use request-scoped logger
    const reqLogger = logger.child({ requestId, userId: user.id });
    reqLogger.info('Processing broadcast request');
    
    // ... handle request
  }
);
```

### Bun SQLite Pattern
```typescript
import { Database } from 'bun:sqlite';

const db = new Database('phantom-ping.db');

// Use parameterized queries
const stmt = db.prepare('SELECT * FROM users WHERE organization_id = ? AND pin_hash = ?');
const user = stmt.get(orgId, pinHash);

// Transactions for atomic operations
db.transaction(() => {
  db.run('UPDATE users SET role = ? WHERE id = ?', ['admin', userId]);
  db.run('INSERT INTO audit_log VALUES (?, ?)', [userId, 'promoted']);
})();
```

### Bun Password Hashing Pattern
```typescript
// Hash PIN with SHA-256
const pinHash = await Bun.password.hash(pin, {
  algorithm: 'sha256',
  memoryCost: 4,
  timeCost: 3
});

// Verify PIN
const isValid = await Bun.password.verify(pin, storedHash);
```

### Bun WebSocket Pattern
```typescript
Bun.serve({
  port: 3000,
  fetch(req, server) {
    // Upgrade HTTP to WebSocket
    const url = new URL(req.url);
    if (url.pathname === '/ws') {
      const token = url.searchParams.get('token');
      // Verify JWT token
      const user = verifyJWT(token);
      if (!user) return new Response('Unauthorized', { status: 401 });
      
      server.upgrade(req, { data: { userId: user.id } });
      return;
    }
    // Regular HTTP routes handled by Hono
    return app.fetch(req, server);
  },
  websocket: {
    open(ws) {
      const userId = ws.data.userId;
      // Store connection mapping
      connectionMap.set(userId, ws);
    },
    message(ws, message) {
      // Handle incoming messages
      const data = JSON.parse(message);
      if (data.event === 'message:acknowledge') {
        // Process acknowledgement
      }
    },
    close(ws) {
      // Clean up connection
      const userId = ws.data.userId;
      connectionMap.delete(userId);
    },
    ping(ws) {
      ws.pong();
    }
  }
});
```

### Service Layer Pattern
```typescript
// Services should handle business logic, not routes
class BroadcastService {
  async sendBroadcast(senderId: string, payload: BroadcastPayload) {
    // 1. Validate sender permissions
    // 2. Determine recipients based on scope and role
    // 3. Store message in database
    // 4. Deliver via WebSocket
    // 5. Return result
  }
}
```

### API Response Helpers Pattern
```typescript
import { successResponse, ApiError } from '@/utils/apiResponse';

// Success response (200)
return successResponse(c, 'Operation successful', {
  userId: '123',
  name: 'John Doe'
});

// Success with custom status code (201 Created)
return successResponse(c, 'Resource created', { id: '123' }, 201);

// Bad Request (400)
return ApiError.badRequest(c, 'Invalid input', { field: 'email' });

// Unauthorized (401)
return ApiError.unauthorized(c, 'Invalid credentials', 'AUTH_INVALID_CREDENTIALS');

// Forbidden (403)
return ApiError.forbidden(c, 'Insufficient permissions', 'AUTH_FORBIDDEN');

// Not Found (404)
return ApiError.notFound(c, 'User not found', 'USER_NOT_FOUND');

// Conflict (409)
return ApiError.conflict(c, 'Email already exists', 'EMAIL_EXISTS');

// Server Error (500)
return ApiError.serverError(c, 'An unexpected error occurred');
```

**Response Format:**
```typescript
// Success Response
{
  "status": true,
  "message": "Operation successful",
  "data": {
    "userId": "123",
    "name": "John Doe"
  }
}

// Error Response
{
  "status": false,
  "message": "Invalid input",
  "data": {
    "code": "INVALID_INPUT",
    "details": {
      "field": "email"
    }
  }
}
```

### Zod Validation Pattern
```typescript
import { z } from 'zod';
import { validateBody, getValidatedBody } from '@/middleware/validation';

// 1. Define validation schema in src/validators/
export const createUserSchema = z.object({
  name: z.string()
    .min(1, 'Name is required')
    .max(100, 'Name must be 100 characters or less')
    .trim(),
  email: z.string()
    .email('Invalid email format')
    .trim()
    .toLowerCase(),
  role: z.enum(['owner', 'admin', 'supervisor', 'normal'], {
    errorMap: () => ({ message: 'Invalid role' })
  }),
  organizationId: z.string()
    .min(1, 'Organization ID is required')
    .max(15, 'Organization ID must be 15 characters or less')
    .trim(),
  supervisorTopicId: z.string()
    .optional(),
});

// Export inferred type
export type CreateUserRequest = z.infer<typeof createUserSchema>;

// 2. Apply validation middleware in route
import { Hono } from 'hono';
import { createUserSchema, type CreateUserRequest } from '@/validators/userSchemas';

const app = new Hono();

app.post('/users', validateBody(createUserSchema), async (c) => {
  // Get type-safe validated data
  const userData = getValidatedBody<CreateUserRequest>(c);
  
  // Data is already validated and transformed (trimmed, lowercased, etc.)
  // No need for manual validation
  
  try {
    const user = await createUser(userData);
    return successResponse(c, 'User created successfully', user, 201);
  } catch (error) {
    return ApiError.serverError(c, 'Failed to create user');
  }
});
```

**Validation Error Response:**
```json
{
  "status": false,
  "message": "Validation failed",
  "data": {
    "code": "INVALID_INPUT",
    "details": {
      "errors": [
        {
          "field": "email",
          "message": "Invalid email format"
        },
        {
          "field": "organizationId",
          "message": "Organization ID must be 15 characters or less"
        }
      ]
    }
  }
}
```

### Common Zod Validation Patterns
```typescript
// Required string with trim
z.string().min(1, 'Field is required').trim()

// Optional string
z.string().optional()

// Email validation
z.string().email('Invalid email format').trim().toLowerCase()

// Enum validation
z.enum(['low', 'medium', 'high'], {
  errorMap: () => ({ message: 'Must be low, medium, or high' })
})

// Number with constraints
z.number().int().positive().min(1).max(100)

// Boolean with default
z.boolean().default(true)

// Array validation
z.array(z.string()).min(1, 'At least one item required')

// Nested object
z.object({
  user: z.object({
    name: z.string(),
    email: z.string().email(),
  }),
})

// Custom refinement
z.string()
  .refine((val) => /^\d{6}$/.test(val), {
    message: 'PIN must be exactly 6 digits',
  })

// Conditional validation
z.object({
  role: z.enum(['owner', 'admin', 'supervisor', 'normal']),
  supervisorTopicId: z.string().optional(),
}).refine(
  (data) => data.role !== 'supervisor' || data.supervisorTopicId,
  {
    message: 'Supervisor must have a topic assigned',
    path: ['supervisorTopicId'],
  }
)
```

### Complete Route Handler Pattern
```typescript
import { Hono } from 'hono';
import { authMiddleware, getAuthUser } from '@/middleware/auth';
import { authorize } from '@/middleware/authorization';
import { validateBody, getValidatedBody } from '@/middleware/validation';
import { successResponse, ApiError } from '@/utils/apiResponse';
import { loginSchema, type LoginRequest } from '@/validators/authSchemas';
import { login } from '@/services/authService';
import { logger } from '@/logger';

const auth = new Hono();

auth.post('/login', validateBody(loginSchema), async (c) => {
  try {
    // Get validated data (type-safe)
    const { pin, organizationId } = getValidatedBody<LoginRequest>(c);

    // Call service layer
    const result = await login(pin, organizationId);

    // Log success
    logger.info(
      { userId: result.user.userId, organizationId: result.user.organizationId },
      'User logged in successfully'
    );

    // Return success response
    return successResponse(c, 'Login successful', result);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Handle specific errors
    if (errorMessage.includes('Invalid PIN or Organization ID')) {
      logger.warn({ error: errorMessage }, 'Login failed - invalid credentials');
      return ApiError.unauthorized(
        c,
        'Invalid PIN or Organization ID',
        'AUTH_INVALID_CREDENTIALS'
      );
    }

    // Handle unexpected errors
    logger.error({ error: errorMessage }, 'Login failed with unexpected error');
    return ApiError.serverError(c, 'An error occurred during login');
  }
});

// Protected route with multiple middleware
auth.post(
  '/protected',
  authMiddleware,                           // Verify JWT
  authorize({ roles: ['owner', 'admin'] }), // Check role
  validateBody(mySchema),                   // Validate body
  async (c) => {
    const user = getAuthUser(c);
    const data = getValidatedBody<MyType>(c);
    
    // Handle request...
    return successResponse(c, 'Success', { /* data */ });
  }
);

export default auth;
```

### Legacy Error Response Pattern (DO NOT USE)
```typescript
// ❌ OLD PATTERN - Do not use
return c.json({
  error: {
    code: 'ERROR_CODE',
    message: 'Human-readable message',
    details: optionalDetails
  }
}, statusCode);

// ✅ NEW PATTERN - Always use ApiError helpers
import { ApiError } from '@/utils/apiResponse';

return ApiError.unauthorized(c, 'Invalid or expired token', 'AUTH_UNAUTHORIZED');
return ApiError.badRequest(c, 'Invalid input', { field: 'email' });
return ApiError.serverError(c, 'An unexpected error occurred');
```

### Global Error Handler with Logging
```typescript
import { ErrorHandler } from 'hono';
import { ApiError } from '@/utils/apiResponse';
import { logger } from '@/logger';

export const errorHandler: ErrorHandler = (err, c) => {
  const requestId = c.get('requestId');
  const userId = c.get('user')?.id;
  
  logger.error({
    requestId,
    userId,
    error: err,
    stack: err.stack,
    path: c.req.path,
    method: c.req.method
  }, 'Unhandled error');
  
  // Use ApiError helper for consistent response format
  return ApiError.serverError(c, 'An unexpected error occurred');
};

// Apply to Hono app
app.onError(errorHandler);
```

## Best Practices Checklist

### Request Handling
- ✅ **Always use Zod schemas** for validation - never manual validation
- ✅ **Always use API response helpers** - `successResponse()` and `ApiError.*`
- ✅ **Apply validation middleware** before route handlers
- ✅ **Use type-safe helpers** - `getValidatedBody()`, `getAuthUser()`
- ✅ **Log all operations** with appropriate context (requestId, userId)

### Route Structure
```typescript
// ✅ CORRECT: Middleware chain with validation
app.post('/endpoint',
  authMiddleware,              // 1. Authenticate
  authorize({ roles: [...] }), // 2. Authorize
  validateBody(schema),        // 3. Validate
  async (c) => {               // 4. Handle
    const user = getAuthUser(c);
    const data = getValidatedBody<Type>(c);
    // ... business logic
    return successResponse(c, 'Success', result);
  }
);

// ❌ INCORRECT: Manual validation and inconsistent responses
app.post('/endpoint', async (c) => {
  const body = await c.req.json();
  if (!body.field) {
    return c.json({ error: 'Missing field' }, 400); // Wrong!
  }
  // ...
});
```

### Error Handling
- ✅ **Use try-catch blocks** in route handlers
- ✅ **Use ApiError helpers** for all error responses
- ✅ **Log errors** with context before returning
- ✅ **Use specific error codes** for different error types
- ❌ **Never expose** sensitive information in error messages
- ❌ **Never use** raw `c.json()` for errors

### Validation
- ✅ **Define schemas** in `src/validators/` directory
- ✅ **Export inferred types** using `z.infer<typeof schema>`
- ✅ **Use `.trim()`** on all string fields
- ✅ **Use descriptive error messages** in schemas
- ✅ **Test validation schemas** with unit tests
- ❌ **Never skip validation** on user input

### Service Layer
- ✅ **Keep business logic** in services, not routes
- ✅ **Return plain data** from services (not HTTP responses)
- ✅ **Throw errors** from services, catch in routes
- ✅ **Use transactions** for multi-step database operations
- ❌ **Never access** request/response objects in services

## Important Notes

- Always verify organization membership before any operation
- Supervisors can only broadcast to their assigned topic (stored in `supervisor_topic_id`)
- When promoting to Supervisor, set `supervisor_topic_id`; when demoting, clear it
- Prevent Admin/Supervisor role overlap with validation
- Use UUIDv7 for all IDs except organization ID (user-provided)
- Store refresh tokens in database for revocation capability
- Implement automatic token refresh on 401 errors in client
- Clean up WebSocket connections on user logout or token invalidation
- Always use Zod for validation and API response helpers for consistency