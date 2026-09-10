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
exports.SessionsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const MAX_FUTURE_DRIFT_MS = 60_000;
const MAX_PAST_DRIFT_MS = 30 * 24 * 60 * 60 * 1000;
let SessionsService = class SessionsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async list(userId, opts) {
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
        let nextCursor;
        if (items.length > limit) {
            const next = items.pop();
            nextCursor = next.id;
        }
        return { items, nextCursor };
    }
    async getActive(userId) {
        return this.prisma.studySession.findFirst({
            where: { userId, state: { in: ['running', 'paused'] } },
            orderBy: { startedAt: 'desc' },
        });
    }
    async getOne(userId, id) {
        const session = await this.prisma.studySession.findFirst({
            where: { id, userId },
        });
        if (!session)
            throw new common_1.NotFoundException('Session not found');
        return session;
    }
    async create(userId, dto) {
        await this.assertSubjectOwned(userId, dto.subjectId);
        const now = Date.now();
        const startedMs = new Date(dto.startedAt).getTime();
        if (startedMs > now + MAX_FUTURE_DRIFT_MS) {
            throw new common_1.BadRequestException('startedAt is too far in the future');
        }
        if (startedMs < now - MAX_PAST_DRIFT_MS) {
            throw new common_1.BadRequestException('startedAt is too far in the past');
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
        }
        catch (e) {
            if (e?.code === 'P2002') {
                throw new common_1.ConflictException('Session with this id already exists');
            }
            throw e;
        }
    }
    async update(userId, id, dto) {
        const session = await this.getOne(userId, id);
        if (session.state === 'completed' || session.state === 'cancelled') {
            throw new common_1.ForbiddenException('Completed or cancelled sessions are immutable');
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
    async complete(userId, id, dto) {
        const session = await this.getOne(userId, id);
        if (session.state === 'completed') {
            throw new common_1.ConflictException('Session already completed');
        }
        if (session.state === 'cancelled') {
            throw new common_1.ForbiddenException('Cannot complete a cancelled session');
        }
        const startedMs = session.startedAt.getTime();
        const endedMs = new Date(dto.endedAt).getTime();
        if (endedMs < startedMs) {
            throw new common_1.BadRequestException('endedAt is before startedAt');
        }
        const derivedActual = Math.floor((endedMs - startedMs - dto.pausedIntervalsSeconds * 1000) / 1000);
        if (derivedActual < 0) {
            throw new common_1.BadRequestException('pausedIntervalsSeconds exceeds total elapsed');
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
    async cancel(userId, id) {
        const session = await this.getOne(userId, id);
        if (session.state === 'completed') {
            throw new common_1.ForbiddenException('Cannot cancel a completed session');
        }
        return this.prisma.studySession.update({
            where: { id },
            data: { state: 'cancelled', endedAt: new Date() },
        });
    }
    async assertSubjectOwned(userId, subjectId) {
        const subject = await this.prisma.subject.findFirst({
            where: { id: subjectId, userId },
        });
        if (!subject)
            throw new common_1.NotFoundException('Subject not found');
    }
};
exports.SessionsService = SessionsService;
exports.SessionsService = SessionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SessionsService);
//# sourceMappingURL=sessions.service.js.map