import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CompleteSessionDto,
  CreateSessionDto,
  UpdateSessionDto,
} from './dto/session.dto';

const MAX_FUTURE_DRIFT_MS = 60_000;       // R-S5: cap startedAt to now ± 1min
const MAX_PAST_DRIFT_MS = 30 * 24 * 60 * 60 * 1000; // 30 days for offline sync

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(
    userId: string,
    opts: { from?: Date; to?: Date; subjectId?: string; areaId?: string; cursor?: string; limit?: number },
  ) {
    const limit = Math.min(opts.limit ?? 50, 200);
    const items = await this.prisma.studySession.findMany({
      where: {
        userId,
        ...(opts.from || opts.to
          ? { startedAt: { gte: opts.from, lte: opts.to } }
          : {}),
        ...(opts.subjectId ? { subjectId: opts.subjectId } : {}),
      },
      orderBy: { startedAt: 'desc' },
      take: limit + 1,
      ...(opts.cursor ? { cursor: { id: opts.cursor }, skip: 1 } : {}),
    });
    let nextCursor: string | undefined;
    if (items.length > limit) {
      const next = items.pop()!;
      nextCursor = next.id;
    }
    return { items, nextCursor };
  }

  async getActive(userId: string) {
    return this.prisma.studySession.findFirst({
      where: { userId, state: { in: ['running', 'paused'] } },
      orderBy: { startedAt: 'desc' },
    });
  }

  async getOne(userId: string, id: string) {
    const session = await this.prisma.studySession.findFirst({
      where: { id, userId },
    });
    if (!session) throw new NotFoundException('Session not found');
    return session;
  }

  /**
   * Create a session.
   * - `id` is client-issued (R-S17).
   * - `subjectId` must belong to the user.
   * - `startedAt` is clamped (R-S5): not in the future beyond 1 minute,
   *   not in the past beyond 30 days (offline sync window).
   */
  async create(userId: string, dto: CreateSessionDto) {
    await this.assertSubjectOwned(userId, dto.subjectId);

    const now = Date.now();
    const startedMs = new Date(dto.startedAt).getTime();
    if (startedMs > now + MAX_FUTURE_DRIFT_MS) {
      throw new BadRequestException('startedAt is too far in the future');
    }
    if (startedMs < now - MAX_PAST_DRIFT_MS) {
      throw new BadRequestException('startedAt is too far in the past');
    }

    try {
      return await this.prisma.studySession.create({
        data: {
          id: dto.id,
          userId,
          subjectId: dto.subjectId,
          topic: dto.topic,
          plannedDurationSeconds: dto.plannedDurationSeconds,
          startedAt: new Date(dto.startedAt),
          goalText: dto.goalText,
          state: 'running',
        },
      });
    } catch (e: any) {
      if (e?.code === 'P2002') {
        throw new ConflictException('Session with this id already exists');
      }
      throw e;
    }
  }

  /**
   * Partial update — only allowed on sessions that are NOT completed.
   * After completion, the row is immutable except for `notes`, `focusRating`,
   * `energyRating` (R-S13).
   */
  async update(userId: string, id: string, dto: UpdateSessionDto) {
    const session = await this.getOne(userId, id);
    if (session.state === 'completed' || session.state === 'cancelled') {
      throw new ForbiddenException('Completed or cancelled sessions are immutable');
    }
    return this.prisma.studySession.update({
      where: { id },
      data: {
        ...(dto.topic !== undefined ? { topic: dto.topic } : {}),
        ...(dto.goalText !== undefined ? { goalText: dto.goalText } : {}),
        ...(dto.state !== undefined ? { state: dto.state } : {}),
        ...(dto.pausedIntervalsSeconds !== undefined
          ? { pausedIntervalsSeconds: dto.pausedIntervalsSeconds }
          : {}),
        ...(dto.endedAt !== undefined ? { endedAt: new Date(dto.endedAt) } : {}),
        ...(dto.actualDurationSeconds !== undefined
          ? { actualDurationSeconds: dto.actualDurationSeconds }
          : {}),
      },
    });
  }

  /**
   * Complete a session. Final state, immutable from here except notes/ratings.
   * Server re-derives actual duration from timestamps as a sanity check.
   */
  async complete(userId: string, id: string, dto: CompleteSessionDto) {
    const session = await this.getOne(userId, id);
    if (session.state === 'completed') {
      throw new ConflictException('Session already completed');
    }
    if (session.state === 'cancelled') {
      throw new ForbiddenException('Cannot complete a cancelled session');
    }

    const startedMs = session.startedAt.getTime();
    const endedMs = new Date(dto.endedAt).getTime();
    if (endedMs < startedMs) {
      throw new BadRequestException('endedAt is before startedAt');
    }
    const derivedActual = Math.floor(
      (endedMs - startedMs - dto.pausedIntervalsSeconds * 1000) / 1000,
    );
    if (derivedActual < 0) {
      throw new BadRequestException('pausedIntervalsSeconds exceeds total elapsed');
    }

    return this.prisma.studySession.update({
      where: { id },
      data: {
        state: 'completed',
        endedAt: new Date(dto.endedAt),
        actualDurationSeconds: dto.actualDurationSeconds,
        pausedIntervalsSeconds: dto.pausedIntervalsSeconds,
        goalResult: dto.goalResult,
        focusRating: dto.focusRating,
        energyRating: dto.energyRating,
        notes: dto.notes,
      },
    });
  }

  async cancel(userId: string, id: string) {
    const session = await this.getOne(userId, id);
    if (session.state === 'completed') {
      throw new ForbiddenException('Cannot cancel a completed session');
    }
    return this.prisma.studySession.update({
      where: { id },
      data: { state: 'cancelled', endedAt: new Date() },
    });
  }

  private async assertSubjectOwned(userId: string, subjectId: string) {
    const subject = await this.prisma.subject.findFirst({
      where: { id: subjectId, userId },
    });
    if (!subject) throw new NotFoundException('Subject not found');
  }
}