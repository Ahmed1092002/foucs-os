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
exports.DailyReviewsService = void 0;
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
let DailyReviewsService = class DailyReviewsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async list(userId, from, to) {
        return this.prisma.dailyReview.findMany({
            where: {
                userId,
                ...(from || to
                    ? { reviewDate: { gte: from ? parseDate(from) : undefined, lte: to ? parseDate(to) : undefined } }
                    : {}),
            },
            orderBy: { reviewDate: 'desc' },
        });
    }
    async getForDate(userId, date) {
        const reviewDate = parseDate(date);
        return this.prisma.dailyReview.findUnique({
            where: { userId_reviewDate: { userId, reviewDate } },
        });
    }
    async upsert(userId, date, dto) {
        const reviewDate = parseDate(date);
        return this.prisma.dailyReview.upsert({
            where: { userId_reviewDate: { userId, reviewDate } },
            update: {
                ...(dto.productivityRating !== undefined
                    ? { productivityRating: dto.productivityRating }
                    : {}),
                ...(dto.energyRating !== undefined ? { energyRating: dto.energyRating } : {}),
                ...(dto.focusRating !== undefined ? { focusRating: dto.focusRating } : {}),
                ...(dto.wentWell !== undefined ? { wentWell: dto.wentWell } : {}),
                ...(dto.blockedBy !== undefined ? { blockedBy: dto.blockedBy } : {}),
            },
            create: {
                userId,
                reviewDate,
                productivityRating: dto.productivityRating,
                energyRating: dto.energyRating,
                focusRating: dto.focusRating,
                wentWell: dto.wentWell,
                blockedBy: dto.blockedBy,
            },
        });
    }
};
exports.DailyReviewsService = DailyReviewsService;
exports.DailyReviewsService = DailyReviewsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], DailyReviewsService);
//# sourceMappingURL=daily-reviews.service.js.map