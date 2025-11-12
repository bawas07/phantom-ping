import type { Context, Next } from 'hono';
import { verifyToken, type JWTPayload } from '@/utils/auth';
import { ApiError } from '@/utils/apiResponse';

/**
 * Extended context with authenticated user information
 */
export interface AuthContext {
  user: JWTPayload;
}

/**
 * Authentication middleware that verifies JWT tokens
 * Extracts user information from the token and attaches it to the request context
 * 
 * Usage:
 * app.use('/api/protected/*', authMiddleware);
 * 
 * @param c - Hono context
 * @param next - Next middleware function
 * @returns Response or calls next middleware
 */
export async function authMiddleware(c: Context, next: Next) {
  try {
    // Extract token from Authorization header
    const authHeader = c.req.header('Authorization');
    
    if (!authHeader) {
      return ApiError.unauthorized(c, 'Missing authorization header');
    }

    // Check for Bearer token format
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return c.json(
        {
          status: false,
          message: 'Invalid authorization header format. Expected: Bearer <token>',
          data: {
            code: 'AUTH_UNAUTHORIZED',
          },
        },
        401
      );
    }

    const token = parts[1]!;

    // Verify and decode the token
    let payload: JWTPayload;
    try {
      payload = verifyToken(token);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      // Handle token expiration specifically
      if (errorMessage.includes('expired')) {
        return c.json(
          {
            status: false,
            message: 'Access token has expired. Please refresh your token.',
            data: {
              code: 'AUTH_TOKEN_EXPIRED',
            },
          },
          401
        );
      }

      // Handle other token verification errors
      return c.json(
        {
          status: false,
          message: 'Invalid or malformed token',
          data: {
            code: 'AUTH_INVALID_TOKEN',
            details: errorMessage,
          },
        },
        401
      );
    }

    // Ensure this is an access token, not a refresh token
    if (payload.type !== 'access') {
      return c.json(
        {
          status: false,
          message: 'Invalid token type. Access token required.',
          data: {
            code: 'AUTH_INVALID_TOKEN',
          },
        },
        401
      );
    }

    // Attach user information to context
    c.set('user', payload);

    // Continue to next middleware/handler
    await next();
  } catch (error) {
    // Handle unexpected errors
    return c.json(
      {
        status: false,
        message: 'An unexpected error occurred during authentication',
        data: {
          code: 'SERVER_ERROR',
        },
      },
      500
    );
  }
}

/**
 * Helper function to get authenticated user from context
 * Use this in route handlers to access user information
 * 
 * @param c - Hono context
 * @returns The authenticated user payload
 */
export function getAuthUser(c: Context): JWTPayload {
  const user = c.get('user') as JWTPayload | undefined;
  
  if (!user) {
    throw new Error('User not authenticated. Ensure authMiddleware is applied to this route.');
  }
  
  return user;
}
