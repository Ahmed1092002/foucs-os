import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

interface AuthUser { id: string }

/**
 * Pull all rows for the current user that have been updated since `since`.
 * One envelope per entity. Server returns its own clock as `serverTime` so
 * the client can use it for the next pull.
 *
 * Conflict policy: last-writer-wins. The client upserts by primary key.
 */
@ApiTags('sync')
@ApiBearerAuth()
@Controller('sync')
@UseGuards(JwtAuthGuard)
export class SyncController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('pull')
  @ApiOperation({ summary: 'Pull all server-side changes since a timestamp' })
  @ApiResponse({ status: 200, description: 'Sync payload with all entities' })
  @ApiResponse({ status: 400, description: 'Invalid since timestamp' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async pull(
    @CurrentUser() user: AuthUser,
    @Query('since') since?: string,
  ) {
    const sinceDate = since ? new Date(since) : new Date(0);
    if (Number.isNaN(sinceDate.getTime())) {
      throw new Error('Invalid since timestamp');
    }
    const userId = user.id;

    const [areas, subjects, sessions, dailyPlans, dailyReviews, courses, modules, lessons] = await Promise.all([
      this.prisma.learningArea.findMany({ where: { userId, updatedAt: { gt: sinceDate } } }),
      this.prisma.subject.findMany({ where: { userId, updatedAt: { gt: sinceDate } } }),
      this.prisma.studySession.findMany({ where: { userId, updatedAt: { gt: sinceDate } } }),
      this.prisma.dailyPlan.findMany({
        where: { userId, updatedAt: { gt: sinceDate } },
        include: { items: true },
      }),
      this.prisma.dailyReview.findMany({ where: { userId, updatedAt: { gt: sinceDate } } }),
      this.prisma.course.findMany({
        where: { userId, updatedAt: { gt: sinceDate } },
        include: { modules: { include: { lessons: true } } },
      }),
      // Modules + lessons are nested under courses; pull them via their
      // course's userId for a single round-trip.
      this.prisma.module.findMany({
        where: { course: { userId, updatedAt: { gt: sinceDate } }, updatedAt: { gt: sinceDate } },
      }),
      this.prisma.lesson.findMany({
        where: { module: { course: { userId } }, updatedAt: { gt: sinceDate } },
      }),
    ]);

    return {
      serverTime: new Date().toISOString(),
      since: sinceDate.toISOString(),
      areas,
      subjects,
      sessions,
      dailyPlans,
      dailyReviews,
      courses,
      modules,
      lessons,
    };
  }
}