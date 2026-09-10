import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Use this guard from any module that imports AuthModule — JwtAuthGuard
 * must be instantiated in a module where PassportModule is registered.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}