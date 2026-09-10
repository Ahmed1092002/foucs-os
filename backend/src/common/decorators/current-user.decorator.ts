import { ExecutionContext, createParamDecorator } from '@nestjs/common';

/**
 * Extracts the authenticated user injected by JwtAuthGuard.
 * Shape: { id: string; email: string }.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest();
    return req.user;
  },
);