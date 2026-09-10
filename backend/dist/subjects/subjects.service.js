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
exports.SubjectsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let SubjectsService = class SubjectsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async list(userId, areaId, status) {
        return this.prisma.subject.findMany({
            where: {
                userId,
                ...(areaId ? { areaId } : {}),
                ...(status ? { status } : {}),
            },
            orderBy: [{ priority: 'desc' }, { createdAt: 'asc' }],
        });
    }
    async getOne(userId, id) {
        const subject = await this.prisma.subject.findFirst({
            where: { id, userId },
            include: { area: true },
        });
        if (!subject)
            throw new common_1.NotFoundException('Subject not found');
        const stats = await this.computeStats(userId, subject.id);
        return { ...subject, ...stats };
    }
    async create(userId, dto) {
        const area = await this.prisma.learningArea.findFirst({
            where: { id: dto.areaId, userId },
        });
        if (!area)
            throw new common_1.NotFoundException('Area not found');
        return this.prisma.subject.create({
            data: {
                userId,
                areaId: dto.areaId,
                name: dto.name,
                description: dto.description,
                color: dto.color,
                targetHours: dto.targetHours,
                priority: dto.priority ?? 0,
                deadline: dto.deadline ? new Date(dto.deadline) : null,
            },
        });
    }
    async update(userId, id, dto) {
        await this.getOne(userId, id);
        return this.prisma.subject.update({
            where: { id },
            data: {
                ...(dto.name !== undefined ? { name: dto.name } : {}),
                ...(dto.description !== undefined ? { description: dto.description } : {}),
                ...(dto.color !== undefined ? { color: dto.color } : {}),
                ...(dto.targetHours !== undefined ? { targetHours: dto.targetHours } : {}),
                ...(dto.priority !== undefined ? { priority: dto.priority } : {}),
                ...(dto.deadline !== undefined
                    ? { deadline: dto.deadline ? new Date(dto.deadline) : null }
                    : {}),
                ...(dto.status !== undefined ? { status: dto.status } : {}),
            },
        });
    }
    async softDelete(userId, id) {
        await this.getOne(userId, id);
        await this.prisma.subject.update({
            where: { id },
            data: { status: 'archived' },
        });
    }
    async computeStats(_userId, _subjectId) {
        return {
            completedHours: 0,
            sessionsCount: 0,
            percentComplete: 0,
        };
    }
};
exports.SubjectsService = SubjectsService;
exports.SubjectsService = SubjectsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SubjectsService);
//# sourceMappingURL=subjects.service.js.map