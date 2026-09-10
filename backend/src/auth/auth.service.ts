import { Injectable, Logger, UnauthorizedException, ConflictException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomBytes, createHash } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { SignupDto, LoginDto } from './dto/auth.dto';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

interface AccessPayload {
  sub: string;
  email: string;
  type: 'access';
}

interface RefreshPayload {
  sub: string;
  jti: string;
  type: 'refresh';
}

const BCRYPT_COST = 12;
const REFRESH_TTL_DAYS = 30;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async signup(dto: SignupDto): Promise<{ user: PublicUser; tokens: AuthTokens }> {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_COST);
    const timezone = dto.timezone ?? 'UTC';

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        timezone,
        learningAreas: {
          create: {
            name: 'General',
            color: '#5B8DEF',
            icon: 'school',
          },
        },
      },
      select: { id: true, email: true, timezone: true, createdAt: true },
    });

    const tokens = await this.issueTokens(user.id, user.email);
    return { user, tokens };
  }

  async login(dto: LoginDto): Promise<{ user: PublicUser; tokens: AuthTokens }> {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Invalid credentials');

    const tokens = await this.issueTokens(user.id, user.email);
    return {
      user: { id: user.id, email: user.email, timezone: user.timezone, createdAt: user.createdAt },
      tokens,
    };
  }

  async refresh(refreshToken: string): Promise<AuthTokens> {
    let payload: RefreshPayload;
    try {
      payload = await this.jwt.verifyAsync<RefreshPayload>(refreshToken);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
    if (payload.type !== 'refresh') throw new UnauthorizedException('Wrong token type');

    const tokenHash = this.hash(refreshToken);
    const stored = await this.prisma.refreshToken.findUnique({ where: { tokenHash } });
    if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token expired or revoked');
    }

    // Rotation: revoke old, issue new pair.
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, email: true },
    });
    if (!user) throw new UnauthorizedException('User not found');

    return this.issueTokens(user.id, user.email);
  }

  async logout(refreshToken: string): Promise<void> {
    const tokenHash = this.hash(refreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  // ---- helpers ----

  private async issueTokens(userId: string, email: string): Promise<AuthTokens> {
    const accessPayload: AccessPayload = { sub: userId, email, type: 'access' };
    const accessToken = await this.jwt.signAsync(accessPayload, {
      // 15 minutes in seconds (string TTls are typed strictly in @nestjs/jwt v11+).
      expiresIn: 15 * 60,
    });

    const jti = randomBytes(16).toString('hex');
    const refreshPayload: RefreshPayload = { sub: userId, jti, type: 'refresh' };
    const refreshToken = await this.jwt.signAsync(refreshPayload, {
      expiresIn: REFRESH_TTL_DAYS * 24 * 60 * 60,
    });

    const tokenHash = this.hash(refreshToken);
    const expiresAt = new Date(Date.now() + REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);
    await this.prisma.refreshToken.create({
      data: { id: jti, userId, tokenHash, expiresAt },
    });

    return { accessToken, refreshToken };
  }

  private hash(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}

export interface PublicUser {
  id: string;
  email: string;
  timezone: string;
  createdAt: Date;
}