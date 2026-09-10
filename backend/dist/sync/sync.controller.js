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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SyncController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const prisma_service_1 = require("../prisma/prisma.service");
let SyncController = class SyncController {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async pull(user, since) {
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
};
exports.SyncController = SyncController;
__decorate([
    (0, common_1.Get)('pull'),
    (0, swagger_1.ApiOperation)({ summary: 'Pull all server-side changes since a timestamp' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Sync payload with all entities' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Invalid since timestamp' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('since')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "pull", null);
exports.SyncController = SyncController = __decorate([
    (0, swagger_1.ApiTags)('sync'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('sync'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SyncController);
//# sourceMappingURL=sync.controller.js.map