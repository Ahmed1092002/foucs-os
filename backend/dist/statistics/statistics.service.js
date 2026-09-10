"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.StatisticsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let StatisticsService = class StatisticsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async summary(userId, range) {
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
        const totalActual = completedSessions.reduce((s, x) => s + (x.actualDurationSeconds ?? 0), 0);
        const totalPlanned = planItems.reduce((s, x) => s + x.durationSeconds, 0);
        const sessionsCompleted = completedSessions.length;
        const completionRate = totalPlanned === 0
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
    async bySubject(userId, range) {
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
        const map = new Map();
        for (const s of sessions) {
            if (s.subjectId == null)
                continue;
            const existing = map.get(s.subjectId);
            const seconds = s.actualDurationSeconds ?? 0;
            if (existing) {
                existing.actualSeconds += seconds;
                existing.sessions += 1;
            }
            else {
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
    async byDay(userId, fromStr, toStr) {
        const from = new Date(fromStr + 'T00:00:00Z');
        const to = new Date(toStr + 'T23:59:59Z');
        if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
            throw new common_1.BadRequestException('from/to must be YYYY-MM-DD');
        }
        if (from > to) {
            throw new common_1.BadRequestException('from must be <= to');
        }
        const sessions = await this.prisma.studySession.findMany({
            where: {
                userId,
                state: 'completed',
                startedAt: { gte: from, lte: to },
                actualDurationSeconds: { not: null },
            },
            select: { startedAt: true, actualDurationSeconds: true },
        });
        const planItems = await this.prisma.dailyPlanItem.findMany({
            where: {
                dailyPlan: { userId, planDate: { gte: this.toDate(from), lte: this.toDate(to) } },
            },
            select: { dailyPlan: { select: { planDate: true } }, durationSeconds: true },
        });
        const actualByDay = new Map();
        for (const s of sessions) {
            const key = this.toDateKey(s.startedAt);
            actualByDay.set(key, (actualByDay.get(key) ?? 0) + (s.actualDurationSeconds ?? 0));
        }
        const plannedByDay = new Map();
        for (const p of planItems) {
            const key = this.toDateKey(p.dailyPlan.planDate);
            plannedByDay.set(key, (plannedByDay.get(key) ?? 0) + p.durationSeconds);
        }
        const out = [];
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
    async streak(userId) {
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
        const yesterday = this.toDateKey(new Date(Date.now() - 24 * 60 * 60 * 1000));
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
        let longest = 0;
        let run = 0;
        let prev = null;
        const sortedDays = Array.from(dayKeys)
            .sort()
            .map((k) => new Date(k + 'T00:00:00Z'));
        for (const d of sortedDays) {
            if (prev && (d.getTime() - prev.getTime()) === 24 * 60 * 60 * 1000) {
                run++;
            }
            else {
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
    bounds(now, range) {
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
    toDate(d) {
        return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
    }
    toDateKey(d) {
        return d.toISOString().slice(0, 10);
    }
};
exports.StatisticsService = StatisticsService;
exports.StatisticsService = StatisticsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], StatisticsService);
//# sourceMappingURL=statistics.service.js.map