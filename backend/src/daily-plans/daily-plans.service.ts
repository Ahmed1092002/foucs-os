import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReplacePlanDto } from './dto/plan.dto';

/** YYYY-MM-DD parser, rejecting timezone-shifted strings. */
function parseDate(s: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    throw new BadRequestException('date must be YYYY-MM-DD');
  }
  const d = new Date(s + 'T00:00:00Z');
  if (Number.isNaN(d.getTime())) {
    throw new BadRequestException('Invalid date');
  }
  return d;
}

@Injectable()
export class DailyPlansService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, from?: string, to?: string) {
    return this.prisma.dailyPlan.findMany({
      where: {
        userId,
        ...(from || to
          ? { planDate: { gte: from ? parseDate(from) : undefined, lte: to ? parseDate(to) : undefined } }
          : {}),
      },
      orderBy: { planDate: 'asc' },
      include: { items: { orderBy: { orderIndex: 'asc' } } },
    });
  }

  async getForDate(userId: string, date: string) {
    const plan = await this.prisma.dailyPlan.findUnique({
      where: { userId_planDate: { userId, planDate: parseDate(date) } },
      include: { items: { orderBy: { orderIndex: 'asc' } } },
    });
    return plan ?? { planDate: parseDate(date), items: [] };
  }

  async replace(userId: string, date: string, dto: ReplacePlanDto) {
    const planDate = parseDate(date);
    // Validate every subject belongs to the user.
    const subjectIds = Array.from(new Set(dto.items.map((i) => i.subjectId)));
    if (subjectIds.length > 0) {
      const count = await this.prisma.subject.count({
        where: { id: { in: subjectIds }, userId },
      });
      if (count !== subjectIds.length) {
        throw new NotFoundException('One or more subjects not found');
      }
    }
    return this.prisma.$transaction(async (tx) => {
      const plan = await tx.dailyPlan.upsert({
        where: { userId_planDate: { userId, planDate } },
        update: {},
        create: { userId, planDate },
      });
      await tx.dailyPlanItem.deleteMany({ where: { dailyPlanId: plan.id } });
      if (dto.items.length > 0) {
        await tx.dailyPlanItem.createMany({
          data: dto.items.map((item, i) => ({
            dailyPlanId: plan.id,
            subjectId: item.subjectId,
            // Prisma's Time columns expect a JS Date — we anchor to planDate
            // so HH:MM maps to that day's wall-clock time.
            startTime: this.hhmmToDate(planDate, item.startTime),
            durationSeconds: item.durationSeconds,
            orderIndex: item.orderIndex ?? i,
          })),
        });
      }
      return tx.dailyPlan.findUnique({
        where: { id: plan.id },
        include: { items: { orderBy: { orderIndex: 'asc' } } },
      });
    });
  }

  private hhmmToDate(planDate: Date, hhmm: string): Date {
    const [h, m] = hhmm.split(':').map((n) => parseInt(n, 10));
    return new Date(Date.UTC(
      planDate.getUTCFullYear(),
      planDate.getUTCMonth(),
      planDate.getUTCDate(),
      h,
      m,
      0,
      0,
    ));
  }

  async remove(userId: string, date: string) {
    const planDate = parseDate(date);
    await this.prisma.dailyPlan.deleteMany({ where: { userId, planDate } });
  }
}