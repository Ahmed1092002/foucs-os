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
exports.CoursesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let CoursesService = class CoursesService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    list(userId, subjectId) {
        return this.prisma.course.findMany({
            where: { userId, ...(subjectId ? { subjectId } : {}) },
            orderBy: { createdAt: 'asc' },
            include: {
                modules: {
                    orderBy: { orderIndex: 'asc' },
                    include: { lessons: { orderBy: { orderIndex: 'asc' } } },
                },
            },
        });
    }
    async getOne(userId, id) {
        const course = await this.prisma.course.findFirst({
            where: { id, userId },
            include: {
                modules: {
                    orderBy: { orderIndex: 'asc' },
                    include: { lessons: { orderBy: { orderIndex: 'asc' } } },
                },
            },
        });
        if (!course)
            throw new common_1.NotFoundException('Course not found');
        return course;
    }
    async create(userId, dto) {
        await this.assertSubjectOwned(userId, dto.subjectId);
        return this.prisma.course.create({
            data: {
                userId,
                subjectId: dto.subjectId,
                name: dto.name,
                description: dto.description,
            },
        });
    }
    async update(userId, id, dto) {
        await this.assertCourseOwned(userId, id);
        return this.prisma.course.update({
            where: { id },
            data: {
                ...(dto.name !== undefined ? { name: dto.name } : {}),
                ...(dto.description !== undefined ? { description: dto.description } : {}),
            },
        });
    }
    async remove(userId, id) {
        await this.assertCourseOwned(userId, id);
        await this.prisma.course.delete({ where: { id } });
    }
    async listModules(userId, courseId) {
        await this.assertCourseOwned(userId, courseId);
        return this.prisma.module.findMany({
            where: { courseId },
            orderBy: { orderIndex: 'asc' },
            include: { lessons: { orderBy: { orderIndex: 'asc' } } },
        });
    }
    async addModule(userId, courseId, dto) {
        await this.assertCourseOwned(userId, courseId);
        const count = await this.prisma.module.count({ where: { courseId } });
        return this.prisma.module.create({
            data: {
                courseId,
                name: dto.name,
                description: dto.description,
                orderIndex: dto.orderIndex ?? count,
            },
        });
    }
    async updateModule(userId, courseId, id, dto) {
        await this.assertCourseOwned(userId, courseId);
        return this.prisma.module.update({
            where: { id },
            data: {
                ...(dto.name !== undefined ? { name: dto.name } : {}),
                ...(dto.description !== undefined ? { description: dto.description } : {}),
                ...(dto.orderIndex !== undefined ? { orderIndex: dto.orderIndex } : {}),
            },
        });
    }
    async removeModule(userId, courseId, id) {
        await this.assertCourseOwned(userId, courseId);
        await this.prisma.module.delete({ where: { id } });
    }
    async listLessons(userId, moduleId) {
        await this.assertModuleOwned(userId, moduleId);
        return this.prisma.lesson.findMany({
            where: { moduleId },
            orderBy: { orderIndex: 'asc' },
        });
    }
    async addLesson(userId, moduleId, dto) {
        await this.assertModuleOwned(userId, moduleId);
        const count = await this.prisma.lesson.count({ where: { moduleId } });
        return this.prisma.lesson.create({
            data: {
                moduleId,
                name: dto.name,
                description: dto.description,
                orderIndex: dto.orderIndex ?? count,
                status: 'not_started',
            },
        });
    }
    async updateLesson(userId, moduleId, id, dto) {
        await this.assertModuleOwned(userId, moduleId);
        const becomingCompleted = dto.status === 'completed';
        return this.prisma.lesson.update({
            where: { id },
            data: {
                ...(dto.name !== undefined ? { name: dto.name } : {}),
                ...(dto.description !== undefined ? { description: dto.description } : {}),
                ...(dto.orderIndex !== undefined ? { orderIndex: dto.orderIndex } : {}),
                ...(dto.status !== undefined
                    ? {
                        status: dto.status,
                        completedAt: becomingCompleted ? new Date() : null,
                    }
                    : {}),
            },
        });
    }
    async removeLesson(userId, moduleId, id) {
        await this.assertModuleOwned(userId, moduleId);
        await this.prisma.lesson.delete({ where: { id } });
    }
    async subjectProgress(userId, subjectId) {
        await this.assertSubjectOwned(userId, subjectId);
        const [subjectSessions, lessons] = await Promise.all([
            this.prisma.studySession.findMany({
                where: {
                    userId,
                    subjectId,
                    state: 'completed',
                    actualDurationSeconds: { not: null },
                },
                select: { actualDurationSeconds: true, plannedDurationSeconds: true },
            }),
            this.prisma.lesson.findMany({
                where: { module: { course: { subjectId } } },
                select: { status: true },
            }),
        ]);
        const totalActual = subjectSessions.reduce((s, x) => s + (x.actualDurationSeconds ?? 0), 0);
        const totalLessons = lessons.length;
        const completedLessons = lessons.filter((l) => l.status === 'completed').length;
        const subject = await this.prisma.subject.findFirst({
            where: { id: subjectId, userId },
            select: { targetHours: true },
        });
        const targetSeconds = subject ? Number(subject.targetHours) * 3600 : 0;
        const percentTime = targetSeconds === 0 ? 0 : Math.min(1, totalActual / targetSeconds);
        const percentLessons = totalLessons === 0 ? 0 : completedLessons / totalLessons;
        const overall = totalLessons === 0 && targetSeconds === 0
            ? 0
            : 0.5 * percentTime + 0.5 * percentLessons;
        return {
            subjectId,
            completedHours: totalActual / 3600,
            targetHours: targetSeconds / 3600,
            percentTime,
            totalLessons,
            completedLessons,
            percentLessons,
            percentComplete: overall,
        };
    }
    async assertSubjectOwned(userId, subjectId) {
        const subject = await this.prisma.subject.findFirst({
            where: { id: subjectId, userId },
        });
        if (!subject)
            throw new common_1.NotFoundException('Subject not found');
    }
    async assertCourseOwned(userId, courseId) {
        const course = await this.prisma.course.findFirst({
            where: { id: courseId, userId },
        });
        if (!course)
            throw new common_1.NotFoundException('Course not found');
    }
    async assertModuleOwned(userId, moduleId) {
        const module = await this.prisma.module.findFirst({
            where: { id: moduleId, course: { userId } },
        });
        if (!module)
            throw new common_1.NotFoundException('Module not found');
    }
};
exports.CoursesService = CoursesService;
exports.CoursesService = CoursesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CoursesService);
//# sourceMappingURL=courses.service.js.map