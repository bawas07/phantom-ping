import { Hono } from 'hono';
import { successResponse, ApiError } from '@/utils/apiResponse';
import { login, refreshTokens, logout } from '@/services/authService';
import { authMiddleware, getAuthUser } from '@/middleware/auth';
import { validateBody, getValidatedBody } from '@/middleware/validation';
import {
  loginSchema,
  refreshTokenSchema,
  logoutSchema,
  type LoginRequest,
  type RefreshTokenRequest,
  type LogoutRequest,
} from '@/validators/authSchemas';
import { logger } from '@/logger';

const auth = new Hono();

/**
 * POST /api/auth/login
 * Authenticates a user with PIN and Organization ID
 * 
 * Request body:
 * {
 *   pin: string,
 *   organizationId: string
 * }
 * 
 * Success response (200):
 * {
 *   status: true,
 *   message: "Login successful",
 *   data: {
 *     accessToken: string,
 *     refreshToken: string,
 *     user: UserProfile
 *   }
 * }
 * 
 * Error responses:
 * - 400: Validation failed
 * - 401: Invalid credentials
 * - 500: Server error
 */
auth.post('/login', validateBody(loginSchema), async (c) => {
  try {
    // Get validated body
    const { pin, organizationId } = getValidatedBody<LoginRequest>(c);

    // Attempt login
    const result = await login(pin, organizationId);

    logger.info(
      { userId: result.user.userId, organizationId: result.user.organizationId },
      'User logged in successfully'
    );

    return successResponse(c, 'Login successful', result);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Handle authentication errors
    if (errorMessage.includes('Invalid PIN or Organization ID')) {
      logger.warn({ error: errorMessage }, 'Login attempt failed - invalid credentials');
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

/**
 * POST /api/auth/refresh
 * Refreshes access and refresh tokens using a valid refresh token
 * 
 * Request body:
 * {
 *   refreshToken: string
 * }
 * 
 * Success response (200):
 * {
 *   status: true,
 *   message: "Token refreshed successfully",
 *   data: {
 *     accessToken: string,
 *     refreshToken: string
 *   }
 * }
 * 
 * Error responses:
 * - 400: Validation failed
 * - 401: Invalid or expired refresh token
 * - 500: Server error
 */
auth.post('/refresh', validateBody(refreshTokenSchema), async (c) => {
  try {
    // Get validated body
    const { refreshToken } = getValidatedBody<RefreshTokenRequest>(c);

    // Attempt token refresh
    const result = await refreshTokens(refreshToken);

    logger.info('Tokens refreshed successfully');

    return successResponse(c, 'Token refreshed successfully', result);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Handle token errors
    if (errorMessage.includes('Invalid refresh token')) {
      logger.warn({ error: errorMessage }, 'Token refresh failed - invalid token');
      return ApiError.unauthorized(c, 'Invalid refresh token', 'AUTH_INVALID_REFRESH_TOKEN');
    }

    if (errorMessage.includes('expired')) {
      logger.warn({ error: errorMessage }, 'Token refresh failed - expired token');
      return ApiError.unauthorized(
        c,
        'Refresh token has expired',
        'AUTH_REFRESH_TOKEN_EXPIRED'
      );
    }

    if (errorMessage.includes('User not found')) {
      logger.warn({ error: errorMessage }, 'Token refresh failed - user not found');
      return ApiError.unauthorized(
        c,
        'User associated with token not found',
        'AUTH_USER_NOT_FOUND'
      );
    }

    // Handle unexpected errors
    logger.error({ error: errorMessage }, 'Token refresh failed with unexpected error');
    return ApiError.serverError(c, 'An error occurred during token refresh');
  }
});

/**
 * POST /api/auth/logout
 * Logs out a user by invalidating their refresh token
 * Requires authentication (access token in Authorization header)
 * 
 * Request headers:
 * Authorization: Bearer <access_token>
 * 
 * Request body:
 * {
 *   refreshToken: string
 * }
 * 
 * Success response (200):
 * {
 *   status: true,
 *   message: "Logout successful",
 *   data: {}
 * }
 * 
 * Error responses:
 * - 400: Validation failed
 * - 401: Invalid access token or refresh token
 * - 500: Server error
 */
auth.post('/logout', authMiddleware, validateBody(logoutSchema), async (c) => {
  try {
    // Get validated body
    const { refreshToken } = getValidatedBody<LogoutRequest>(c);

    // Attempt logout
    await logout(refreshToken);

    // Get user info from auth middleware for logging
    const user = getAuthUser(c);
    logger.info(
      { userId: user.userId, organizationId: user.organizationId },
      'User logged out successfully'
    );

    return successResponse(c, 'Logout successful', {});
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Handle token errors
    if (errorMessage.includes('Invalid refresh token')) {
      logger.warn({ error: errorMessage }, 'Logout failed - invalid refresh token');
      return ApiError.unauthorized(c, 'Invalid refresh token', 'AUTH_INVALID_REFRESH_TOKEN');
    }

    // Handle unexpected errors
    logger.error({ error: errorMessage }, 'Logout failed with unexpected error');
    return ApiError.serverError(c, 'An error occurred during logout');
  }
});

export default auth;
