import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSubjectDto, UpdateSubjectDto } from './dto/subject.dto';

@Injectable()
export class SubjectsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, areaId?: string, status?: string) {
    return this.prisma.subject.findMany({
      where: {
        userId,
        ...(areaId ? { areaId } : {}),
        ...(status ? { status } : {}),
      },
      orderBy: [{ priority: 'desc' }, { createdAt: 'asc' }],
    });
  }

  async getOne(userId: string, id: string) {
    const subject = await this.prisma.subject.findFirst({
      where: { id, userId },
      include: { area: true },
    });
    if (!subject) throw new NotFoundException('Subject not found');
    const stats = await this.computeStats(userId, subject.id);
    return { ...subject, ...stats };
  }

  async create(userId: string, dto: CreateSubjectDto) {
    // Ensure area belongs to user.
    const area = await this.prisma.learningArea.findFirst({
      where: { id: dto.areaId, userId },
    });
    if (!area) throw new NotFoundException('Area not found');

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

  async update(userId: string, id: string, dto: UpdateSubjectDto) {
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

  async softDelete(userId: string, id: string): Promise<void> {
    await this.getOne(userId, id);
    // R-S4: subjects keep their sessions via ON DELETE SET NULL.
    // We soft-delete via status='archived' so historical totals remain queryable
    // and the UI can render the placeholder row.
    await this.prisma.subject.update({
      where: { id },
      data: { status: 'archived' },
    });
  }

  /**
   * Compute time-based stats for a subject.
   * MVP formula: percentComplete = clamped completedHours / targetHours.
   * Sessions are added in Phase 2; this is implemented to keep contracts stable.
   */
  private async computeStats(_userId: string, _subjectId: string) {
    return {
      completedHours: 0,
      sessionsCount: 0,
      percentComplete: 0,
    };
  }
}