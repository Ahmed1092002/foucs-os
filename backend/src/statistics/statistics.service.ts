import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type Range = 'today' | 'week' | 'month' | 'all';

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Aggregates planned vs actual study time.
   * "Today" / "week" / "month" are derived from `started_at` of completed sessions.
   * Planned comes from `daily_plan_items` overlapping the range.
   *
   * All numbers are integer seconds. R-S8: stats are always derived from sessions
   * + plans — never stored as pre-computed rows.
   */
  async summary(userId: string, range: Range) {
    const now = new Date();
    const { from, to } = this.bounds(now, range);

    const [completedSessions, planItems] = await Promise.all([
      this.prisma.studySession.findMany({
        where: {
          userId,
          state: 'completed',
          startedAt: { gte: from, lte: to },
          actualDurationSeconds: { not: null },
        },
        select: { actualDurationSeconds: true },
      }),
      this.prisma.dailyPlanItem.findMany({
        where: {
          dailyPlan: { userId, planDate: { gte: this.toDate(from), lte: this.toDate(to) } },
        },
        select: { durationSeconds: true },
      }),
    ]);

    const totalActual = completedSessions.reduce(
      (s, x) => s + (x.actualDurationSeconds ?? 0),
      0,
    );
    const totalPlanned = planItems.reduce((s, x) => s + x.durationSeconds, 0);
    const sessionsCompleted = completedSessions.length;
    const completionRate =
      totalPlanned === 0
        ? null
        : Math.min(1, totalActual / totalPlanned);

    return {
      range,
      from: from.toISOString(),
      to: to.toISOString(),
      totalActualSeconds: totalActual,
      totalPlannedSeconds: totalPlanned,
      sessionsCompleted,
      completionRate,
    };
  }

  async bySubject(userId: string, range: Range) {
    const { from, to } = this.bounds(new Date(), range);
    const sessions = await this.prisma.studySession.findMany({
      where: {
        userId,
        state: 'completed',
        startedAt: { gte: from, lte: to },
        actualDurationSeconds: { not: null },
      },
      select: {
        subjectId: true,
        actualDurationSeconds: true,
        subject: { select: { name: true, color: true } },
      },
    });
    const map = new Map<string, { subjectId: string; name: string; color: string | null; actualSeconds: number; sessions: number }>();
    for (const s of sessions) {
      if (s.subjectId == null) continue;
      const existing = map.get(s.subjectId);
      const seconds = s.actualDurationSeconds ?? 0;
      if (existing) {
        existing.actualSeconds += seconds;
        existing.sessions += 1;
      } else {
        map.set(s.subjectId, {
          subjectId: s.subjectId,
          name: s.subject?.name ?? 'Unknown',
          color: s.subject?.color ?? null,
          actualSeconds: seconds,
          sessions: 1,
        });
      }
    }
    return Array.from(map.values()).sort((a, b) => b.actualSeconds - a.actualSeconds);
  }

  /**
   * Daily totals (planned vs actual) over a date range.
   * Used for the line chart on the stats screen. `from` and `to` are
   * inclusive date strings (YYYY-MM-DD). The endpoint fills zero-buckets
   * for days with no activity so the chart doesn't lie.
   */
  async byDay(userId: string, fromStr: string, toStr: string) {
    const from = new Date(fromStr + 'T00:00:00Z');
    const to = new Date(toStr + 'T23:59:59Z');
    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
      throw new BadRequestException('from/to must be YYYY-MM-DD');
    }
    if (from > to) {
      throw new BadRequestException('from must be <= to');
    }

    // Pull completed sessions in the range (server-side UTC).
    const sessions = await this.prisma.studySession.findMany({
      where: {
        userId,
        state: 'completed',
        startedAt: { gte: from, lte: to },
        actualDurationSeconds: { not: null },
      },
      select: { startedAt: true, actualDurationSeconds: true },
    });

    // Pull plans in the range.
    const planItems = await this.prisma.dailyPlanItem.findMany({
      where: {
        dailyPlan: { userId, planDate: { gte: this.toDate(from), lte: this.toDate(to) } },
      },
      select: { dailyPlan: { select: { planDate: true } }, durationSeconds: true },
    });

    // Bucket by YYYY-MM-DD.
    const actualByDay = new Map<string, number>();
    for (const s of sessions) {
      const key = this.toDateKey(s.startedAt);
      actualByDay.set(key, (actualByDay.get(key) ?? 0) + (s.actualDurationSeconds ?? 0));
    }
    const plannedByDay = new Map<string, number>();
    for (const p of planItems) {
      const key = this.toDateKey(p.dailyPlan.planDate);
      plannedByDay.set(key, (plannedByDay.get(key) ?? 0) + p.durationSeconds);
    }

    // Walk every day in the range.
    const out: { date: string; plannedSeconds: number; actualSeconds: number }[] = [];
    const cursor = new Date(from);
    while (cursor <= to) {
      const key = this.toDateKey(cursor);
      out.push({
        date: key,
        plannedSeconds: plannedByDay.get(key) ?? 0,
        actualSeconds: actualByDay.get(key) ?? 0,
      });
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }
    return out;
  }

  async streak(userId: string) {
    // MVP definition: a day with ≥1 completed session counts.
    const rows = await this.prisma.studySession.findMany({
      where: { userId, state: 'completed' },
      select: { startedAt: true },
      orderBy: { startedAt: 'desc' },
      take: 365,
    });
    if (rows.length === 0) {
      return { current: 0, longest: 0, lastStudyDate: null };
    }
    const dayKeys = new Set(rows.map((r) => this.toDateKey(r.startedAt)));
    const today = this.toDateKey(new Date());
    const yesterday = this.toDateKey(
      new Date(Date.now() - 24 * 60 * 60 * 1000),
    );

    // Walk back day-by-day.
    let current = 0;
    let cursor = dayKeys.has(today)
      ? new Date()
      : dayKeys.has(yesterday)
        ? new Date(Date.now() - 24 * 60 * 60 * 1000)
        : null;
    while (cursor && dayKeys.has(this.toDateKey(cursor))) {
      current++;
      cursor = new Date(cursor.getTime() - 24 * 60 * 60 * 1000);
    }

    // Longest: scan all unique days.
    let longest = 0;
    let run = 0;
    let prev: Date | null = null;
    const sortedDays = Array.from(dayKeys)
      .sort()
      .map((k) => new Date(k + 'T00:00:00Z'));
    for (const d of sortedDays) {
      if (prev && (d.getTime() - prev.getTime()) === 24 * 60 * 60 * 1000) {
        run++;
      } else {
        run = 1;
      }
      longest = Math.max(longest, run);
      prev = d;
    }

    const lastStudy = rows[0]?.startedAt ?? null;
    return {
      current,
      longest,
      lastStudyDate: lastStudy ? lastStudy.toISOString() : null,
    };
  }

  private bounds(now: Date, range: Range): { from: Date; to: Date } {
    const to = now;
    const from = new Date(now);
    switch (range) {
      case 'today':
        from.setUTCHours(0, 0, 0, 0);
        break;
      case 'week':
        from.setUTCDate(from.getUTCDate() - 6);
        from.setUTCHours(0, 0, 0, 0);
        break;
      case 'month':
        from.setUTCMonth(from.getUTCMonth() - 1);
        break;
      case 'all':
        from.setUTCFullYear(2000, 0, 1);
        break;
    }
    return { from, to };
  }

  private toDate(d: Date): Date {
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  }

  private toDateKey(d: Date): string {
    return d.toISOString().slice(0, 10);
  }
}