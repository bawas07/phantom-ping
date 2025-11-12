import type { Context, Next, MiddlewareHandler } from 'hono';
import { z, ZodError } from 'zod';
import { ApiError } from '@/utils/apiResponse';
import { logger } from '@/logger';

/**
 * Validation middleware factory for request body validation
 * Uses Zod schemas to validate and parse request bodies
 * 
 * @param schema - Zod schema to validate against
 * @returns Hono middleware handler
 * 
 * @example
 * app.post('/login', validateBody(loginSchema), async (c) => {
 *   const body = c.get('validatedBody'); // Type-safe validated body
 *   // ...
 * });
 */
export function validateBody<T extends z.ZodType>(schema: T): MiddlewareHandler {
  return async (c: Context, next: Next) => {
    try {
      // Parse request body
      const body = await c.req.json().catch(() => ({}));
      
      // Validate with Zod schema
      const validatedData = schema.parse(body);
      
      // Store validated data in context
      c.set('validatedBody', validatedData);
      
      await next();
    } catch (error) {
      if (error instanceof ZodError) {
        // Format Zod validation errors
        const errors = error.issues.map((issue) => ({
          field: issue.path.join('.'),
          message: issue.message,
        }));
        
        const requestId = c.get('requestId');
        logger.warn({
          requestId,
          validationErrors: errors,
          path: c.req.path,
        }, 'Request validation failed');
        
        return ApiError.badRequest(
          c,
          'Validation failed',
          { errors }
        );
      }
      
      // Handle unexpected errors
      logger.error({ error }, 'Unexpected error during validation');
      return ApiError.serverError(c, 'An error occurred during validation');
    }
  };
}

/**
 * Validation middleware factory for query parameters
 * 
 * @param schema - Zod schema to validate against
 * @returns Hono middleware handler
 */
export function validateQuery<T extends z.ZodType>(schema: T): MiddlewareHandler {
  return async (c: Context, next: Next) => {
    try {
      // Get query parameters
      const query = c.req.query();
      
      // Validate with Zod schema
      const validatedData = schema.parse(query);
      
      // Store validated data in context
      c.set('validatedQuery', validatedData);
      
      await next();
    } catch (error) {
      if (error instanceof ZodError) {
        // Format Zod validation errors
        const errors = error.issues.map((issue) => ({
          field: issue.path.join('.'),
          message: issue.message,
        }));
        
        const requestId = c.get('requestId');
        logger.warn({
          requestId,
          validationErrors: errors,
          path: c.req.path,
        }, 'Query validation failed');
        
        return ApiError.badRequest(
          c,
          'Query validation failed',
          { errors }
        );
      }
      
      // Handle unexpected errors
      logger.error({ error }, 'Unexpected error during query validation');
      return ApiError.serverError(c, 'An error occurred during validation');
    }
  };
}

/**
 * Helper to get validated body from context
 * Use this in route handlers after validateBody middleware
 * 
 * @param c - Hono context
 * @returns Validated body data
 */
export function getValidatedBody<T>(c: Context): T {
  return c.get('validatedBody') as T;
}

/**
 * Helper to get validated query from context
 * Use this in route handlers after validateQuery middleware
 * 
 * @param c - Hono context
 * @returns Validated query data
 */
export function getValidatedQuery<T>(c: Context): T {
  return c.get('validatedQuery') as T;
}
