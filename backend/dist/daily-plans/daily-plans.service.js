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
exports.DailyPlansService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
function parseDate(s) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
        throw new common_1.BadRequestException('date must be YYYY-MM-DD');
    }
    const d = new Date(s + 'T00:00:00Z');
    if (Number.isNaN(d.getTime())) {
        throw new common_1.BadRequestException('Invalid date');
    }
    return d;
}
let DailyPlansService = class DailyPlansService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async list(userId, from, to) {
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
    async getForDate(userId, date) {
        const plan = await this.prisma.dailyPlan.findUnique({
            where: { userId_planDate: { userId, planDate: parseDate(date) } },
            include: { items: { orderBy: { orderIndex: 'asc' } } },
        });
        return plan ?? { planDate: parseDate(date), items: [] };
    }
    async replace(userId, date, dto) {
        const planDate = parseDate(date);
        const subjectIds = Array.from(new Set(dto.items.map((i) => i.subjectId)));
        if (subjectIds.length > 0) {
            const count = await this.prisma.subject.count({
                where: { id: { in: subjectIds }, userId },
            });
            if (count !== subjectIds.length) {
                throw new common_1.NotFoundException('One or more subjects not found');
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
    hhmmToDate(planDate, hhmm) {
        const [h, m] = hhmm.split(':').map((n) => parseInt(n, 10));
        return new Date(Date.UTC(planDate.getUTCFullYear(), planDate.getUTCMonth(), planDate.getUTCDate(), h, m, 0, 0));
    }
    async remove(userId, date) {
        const planDate = parseDate(date);
        await this.prisma.dailyPlan.deleteMany({ where: { userId, planDate } });
    }
};
exports.DailyPlansService = DailyPlansService;
exports.DailyPlansService = DailyPlansService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], DailyPlansService);
//# sourceMappingURL=daily-plans.service.js.map