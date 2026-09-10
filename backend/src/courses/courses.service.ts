import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateCourseDto,
  CreateLessonDto,
  CreateModuleDto,
  UpdateCourseDto,
  UpdateLessonDto,
  UpdateModuleDto,
} from './dto/course.dto';

@Injectable()
export class CoursesService {
  constructor(private readonly prisma: PrismaService) {}

  // ---- courses ----

  list(userId: string, subjectId?: string) {
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

  async getOne(userId: string, id: string) {
    const course = await this.prisma.course.findFirst({
      where: { id, userId },
      include: {
        modules: {
          orderBy: { orderIndex: 'asc' },
          include: { lessons: { orderBy: { orderIndex: 'asc' } } },
        },
      },
    });
    if (!course) throw new NotFoundException('Course not found');
    return course;
  }

  async create(userId: string, dto: CreateCourseDto) {
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

  async update(userId: string, id: string, dto: UpdateCourseDto) {
    await this.assertCourseOwned(userId, id);
    return this.prisma.course.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.assertCourseOwned(userId, id);
    await this.prisma.course.delete({ where: { id } });
  }

  // ---- modules ----

  async listModules(userId: string, courseId: string) {
    await this.assertCourseOwned(userId, courseId);
    return this.prisma.module.findMany({
      where: { courseId },
      orderBy: { orderIndex: 'asc' },
      include: { lessons: { orderBy: { orderIndex: 'asc' } } },
    });
  }

  async addModule(userId: string, courseId: string, dto: CreateModuleDto) {
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

  async updateModule(userId: string, courseId: string, id: string, dto: UpdateModuleDto) {
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

  async removeModule(userId: string, courseId: string, id: string) {
    await this.assertCourseOwned(userId, courseId);
    await this.prisma.module.delete({ where: { id } });
  }

  // ---- lessons ----

  async listLessons(userId: string, moduleId: string) {
    await this.assertModuleOwned(userId, moduleId);
    return this.prisma.lesson.findMany({
      where: { moduleId },
      orderBy: { orderIndex: 'asc' },
    });
  }

  async addLesson(userId: string, moduleId: string, dto: CreateLessonDto) {
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

  async updateLesson(
    userId: string,
    moduleId: string,
    id: string,
    dto: UpdateLessonDto,
  ) {
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

  async removeLesson(userId: string, moduleId: string, id: string) {
    await this.assertModuleOwned(userId, moduleId);
    await this.prisma.lesson.delete({ where: { id } });
  }

  // ---- progress (R-S11: 0.5 × time + 0.5 × lessons) ----

  async subjectProgress(userId: string, subjectId: string) {
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

    // Time-based: completedHours / targetHours across all the subject's sessions
    const totalActual = subjectSessions.reduce(
      (s, x) => s + (x.actualDurationSeconds ?? 0),
      0,
    );
    // Lessons-based
    const totalLessons = lessons.length;
    const completedLessons = lessons.filter((l) => l.status === 'completed').length;

    // We need targetHours for time ratio. Look up the subject.
    const subject = await this.prisma.subject.findFirst({
      where: { id: subjectId, userId },
      select: { targetHours: true },
    });
    const targetSeconds = subject ? Number(subject.targetHours) * 3600 : 0;
    const percentTime =
      targetSeconds === 0 ? 0 : Math.min(1, totalActual / targetSeconds);
    const percentLessons =
      totalLessons === 0 ? 0 : completedLessons / totalLessons;
    const overall =
      totalLessons === 0 && targetSeconds === 0
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

  // ---- ownership helpers ----

  private async assertSubjectOwned(userId: string, subjectId: string) {
    const subject = await this.prisma.subject.findFirst({
      where: { id: subjectId, userId },
    });
    if (!subject) throw new NotFoundException('Subject not found');
  }

  private async assertCourseOwned(userId: string, courseId: string) {
    const course = await this.prisma.course.findFirst({
      where: { id: courseId, userId },
    });
    if (!course) throw new NotFoundException('Course not found');
  }

  private async assertModuleOwned(userId: string, moduleId: string) {
    const module = await this.prisma.module.findFirst({
      where: { id: moduleId, course: { userId } },
    });
    if (!module) throw new NotFoundException('Module not found');
  }
}