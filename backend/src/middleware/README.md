# Authentication Middleware

This directory contains middleware for the Phantom Ping backend.

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
