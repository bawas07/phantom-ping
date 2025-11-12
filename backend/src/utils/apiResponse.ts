import type { Context } from 'hono';

/**
 * Standard API response format
 */
export interface ApiResponse<T = any> {
  status: boolean;
  message: string;
  data: T;
}

/**
 * Error response data structure
 */
export interface ErrorData {
  code: string;
  details?: any;
}

/**
 * Success response data structure
 */
export interface SuccessData<T = any> {
  [key: string]: T;
}

/**
 * Creates a standardized success response
 * 
 * @param c - Hono context
 * @param message - Success message
 * @param data - Response data
 * @param statusCode - HTTP status code (default: 200)
 * @returns JSON response
 */
export function successResponse<T = any>(
  c: Context,
  message: string,
  data: T = {} as T,
  statusCode: number = 200
) {
  return c.json(
    {
      status: true,
      message,
      data,
    } as ApiResponse<T>,
    statusCode as any
  );
}

/**
 * Creates a standardized error response
 * 
 * @param c - Hono context
 * @param message - Error message
 * @param code - Error code
 * @param statusCode - HTTP status code
 * @param details - Optional additional error details
 * @returns JSON response
 */
export function errorResponse(
  c: Context,
  message: string,
  code: string,
  statusCode: number,
  details?: any
) {
  const errorData: ErrorData = { code };
  if (details !== undefined) {
    errorData.details = details;
  }

  return c.json(
    {
      status: false,
      message,
      data: errorData,
    } as ApiResponse<ErrorData>,
    statusCode as any
  );
}

/**
 * Common error response helpers
 */
export const ApiError = {
  /**
   * 400 Bad Request - Invalid input
   */
  badRequest: (c: Context, message: string, details?: any) =>
    errorResponse(c, message, 'INVALID_INPUT', 400, details),

  /**
   * 401 Unauthorized - Authentication required or failed
   */
  unauthorized: (c: Context, message: string, code: string = 'AUTH_UNAUTHORIZED', details?: any) =>
    errorResponse(c, message, code, 401, details),

  /**
   * 403 Forbidden - Insufficient permissions
   */
  forbidden: (c: Context, message: string, code: string = 'AUTH_FORBIDDEN', details?: any) =>
    errorResponse(c, message, code, 403, details),

  /**
   * 404 Not Found - Resource not found
   */
  notFound: (c: Context, message: string, code: string, details?: any) =>
    errorResponse(c, message, code, 404, details),

  /**
   * 409 Conflict - Resource conflict
   */
  conflict: (c: Context, message: string, code: string, details?: any) =>
    errorResponse(c, message, code, 409, details),

  /**
   * 500 Internal Server Error
   */
  serverError: (c: Context, message: string = 'An unexpected error occurred', details?: any) =>
    errorResponse(c, message, 'SERVER_ERROR', 500, details),
};
