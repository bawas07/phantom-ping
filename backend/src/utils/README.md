# Utilities

This directory contains utility functions and helpers used throughout the backend application.

## API Response (`apiResponse.ts`)

Standardized API response formatting utilities for consistent error and success responses across all endpoints.

### Response Format

All API responses follow this structure:

```typescript
{
  status: boolean,      // true for success, false for error
  message: string,      // Human-readable message
  data: object         // Response data or error details
}
```

### Usage Examples

#### Success Responses

```typescript
import { successResponse } from '@/utils/apiResponse';

// Simple success (200)
return successResponse(c, 'User created successfully', { userId: '123' });

// Custom status code (201)
return successResponse(c, 'Resource created', { id: '456' }, 201);
```

#### Error Responses

```typescript
import { ApiError } from '@/utils/apiResponse';

// 400 Bad Request
return ApiError.badRequest(c, 'Invalid email format', { field: 'email' });

// 401 Unauthorized (default code)
return ApiError.unauthorized(c, 'Missing authorization header');

// 401 Unauthorized (custom code)
return ApiError.unauthorized(c, 'Token expired', 'AUTH_TOKEN_EXPIRED');

// 403 Forbidden
return ApiError.forbidden(c, 'Access denied');

// 404 Not Found
return ApiError.notFound(c, 'User not found', 'USER_NOT_FOUND');

// 409 Conflict
return ApiError.conflict(c, 'Email already exists', 'EMAIL_EXISTS');

// 500 Internal Server Error
return ApiError.serverError(c, 'Database connection failed');
```

#### Custom Error Response

```typescript
import { errorResponse } from '@/utils/apiResponse';

return errorResponse(
  c,
  'Custom error message',
  'CUSTOM_ERROR_CODE',
  418,  // Custom status code
  { additionalInfo: 'details' }
);
```

### Error Codes

Standard error codes used throughout the application:

- `AUTH_UNAUTHORIZED` - Missing or invalid authentication
- `AUTH_TOKEN_EXPIRED` - Access token has expired
- `AUTH_INVALID_TOKEN` - Invalid token format or type
- `AUTH_FORBIDDEN` - Insufficient permissions
- `INVALID_INPUT` - Invalid request parameters
- `USER_NOT_FOUND` - User does not exist
- `ORG_NOT_FOUND` - Organization does not exist
- `TOPIC_NOT_FOUND` - Topic does not exist
- `SERVER_ERROR` - Internal server error

### Benefits

- **Consistency**: All API responses follow the same structure
- **Type Safety**: TypeScript interfaces ensure correct usage
- **Maintainability**: Centralized response formatting
- **Testability**: Easy to test and mock responses
- **Documentation**: Self-documenting code with clear helper names
