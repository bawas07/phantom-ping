# Validators

This directory contains Zod validation schemas for request validation across the API.

## Overview

We use [Zod](https://zod.dev/) for runtime type validation and parsing. Zod provides:
- Type-safe validation with TypeScript inference
- Automatic type coercion and transformation (e.g., `.trim()`)
- Detailed error messages
- Composable schemas

## Usage

### 1. Define Validation Schema

Create a Zod schema in the appropriate file (e.g., `authSchemas.ts`):

```typescript
import { z } from 'zod';

export const loginSchema = z.object({
  pin: z.string()
    .min(1, 'PIN is required')
    .trim(),
  organizationId: z.string()
    .min(1, 'Organization ID is required')
    .max(15, 'Organization ID must be 15 characters or less')
    .trim(),
});

// Export inferred TypeScript type
export type LoginRequest = z.infer<typeof loginSchema>;
```

### 2. Apply Validation Middleware

Use the `validateBody` or `validateQuery` middleware in your routes:

```typescript
import { Hono } from 'hono';
import { validateBody, getValidatedBody } from '@/middleware/validation';
import { loginSchema, type LoginRequest } from '@/validators/authSchemas';

const app = new Hono();

app.post('/login', validateBody(loginSchema), async (c) => {
  // Get type-safe validated data
  const { pin, organizationId } = getValidatedBody<LoginRequest>(c);
  
  // Data is already validated and transformed (trimmed, etc.)
  // ...
});
```

### 3. Validation Errors

When validation fails, the middleware automatically returns a 400 Bad Request with detailed error information:

```json
{
  "status": false,
  "message": "Validation failed",
  "data": {
    "code": "INVALID_INPUT",
    "details": {
      "errors": [
        {
          "field": "pin",
          "message": "PIN is required"
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

## Available Middleware

### `validateBody(schema)`

Validates request body against a Zod schema.

```typescript
app.post('/endpoint', validateBody(mySchema), async (c) => {
  const data = getValidatedBody<MyType>(c);
  // ...
});
```

### `validateQuery(schema)`

Validates query parameters against a Zod schema.

```typescript
app.get('/endpoint', validateQuery(mySchema), async (c) => {
  const data = getValidatedQuery<MyType>(c);
  // ...
});
```

## Common Validation Patterns

### Required String with Trim

```typescript
z.string()
  .min(1, 'Field is required')
  .trim()
```

### Optional String

```typescript
z.string()
  .optional()
```

### String with Length Constraints

```typescript
z.string()
  .min(6, 'Must be at least 6 characters')
  .max(15, 'Must be 15 characters or less')
```

### Email Validation

```typescript
z.string()
  .email('Invalid email format')
```

### Enum Validation

```typescript
z.enum(['low', 'medium', 'high'], {
  errorMap: () => ({ message: 'Level must be low, medium, or high' })
})
```

### Number Validation

```typescript
z.number()
  .int('Must be an integer')
  .positive('Must be positive')
  .min(1, 'Must be at least 1')
  .max(100, 'Must be at most 100')
```

### Boolean Validation

```typescript
z.boolean()
  .default(true)
```

### Array Validation

```typescript
z.array(z.string())
  .min(1, 'At least one item required')
  .max(10, 'Maximum 10 items allowed')
```

### Nested Object Validation

```typescript
z.object({
  user: z.object({
    name: z.string(),
    email: z.string().email(),
  }),
  settings: z.object({
    notifications: z.boolean(),
  }),
})
```

### Union Types

```typescript
z.union([
  z.literal('organization'),
  z.literal('topic'),
])
```

### Custom Refinements

```typescript
z.string()
  .refine((val) => val.length === 6, {
    message: 'PIN must be exactly 6 digits',
  })
  .refine((val) => /^\d+$/.test(val), {
    message: 'PIN must contain only digits',
  })
```

## Testing Schemas

Always test your validation schemas:

```typescript
import { describe, test, expect } from 'bun:test';
import { mySchema } from './mySchemas';

describe('My Schema', () => {
  test('should validate valid data', () => {
    const result = mySchema.safeParse({ field: 'value' });
    expect(result.success).toBe(true);
  });

  test('should reject invalid data', () => {
    const result = mySchema.safeParse({ field: '' });
    expect(result.success).toBe(false);
  });
});
```

## Best Practices

1. **Keep schemas close to their usage** - Organize schemas by feature/domain
2. **Export inferred types** - Use `z.infer<typeof schema>` for type safety
3. **Use descriptive error messages** - Help users understand what went wrong
4. **Test edge cases** - Validate empty strings, null, undefined, etc.
5. **Use transformations** - `.trim()`, `.toLowerCase()`, etc. for data normalization
6. **Compose schemas** - Reuse common patterns with `.extend()` or `.merge()`
7. **Document constraints** - Add comments explaining business rules

## Resources

- [Zod Documentation](https://zod.dev/)
- [Zod GitHub](https://github.com/colinhacks/zod)
