import { z } from 'zod';

/**
 * Validation schema for login request
 */
export const loginSchema = z.object({
  pin: z.string()
    .min(1, 'PIN is required')
    .trim(),
  organizationId: z.string()
    .min(1, 'Organization ID is required')
    .max(15, 'Organization ID must be 15 characters or less')
    .trim(),
});

/**
 * Validation schema for refresh token request
 */
export const refreshTokenSchema = z.object({
  refreshToken: z.string()
    .min(1, 'Refresh token is required')
    .trim(),
});

/**
 * Validation schema for logout request
 */
export const logoutSchema = z.object({
  refreshToken: z.string()
    .min(1, 'Refresh token is required')
    .trim(),
});

// Export types inferred from schemas
export type LoginRequest = z.infer<typeof loginSchema>;
export type RefreshTokenRequest = z.infer<typeof refreshTokenSchema>;
export type LogoutRequest = z.infer<typeof logoutSchema>;
