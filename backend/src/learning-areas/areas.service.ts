import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAreaDto, UpdateAreaDto } from './dto/area.dto';

@Injectable()
export class AreasService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string, includeArchived = false) {
    return this.prisma.learningArea.findMany({
      where: { userId, ...(includeArchived ? {} : { archivedAt: null }) },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getOne(userId: string, id: string) {
    const area = await this.prisma.learningArea.findFirst({ where: { id, userId } });
    if (!area) throw new NotFoundException('Area not found');
    return area;
  }

  create(userId: string, dto: CreateAreaDto) {
    return this.prisma.learningArea.create({
      data: { userId, name: dto.name, color: dto.color, icon: dto.icon },
    });
  }

  async update(userId: string, id: string, dto: UpdateAreaDto) {
    await this.getOne(userId, id);
    return this.prisma.learningArea.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.color !== undefined ? { color: dto.color } : {}),
        ...(dto.icon !== undefined ? { icon: dto.icon } : {}),
        ...(dto.archived !== undefined
          ? { archivedAt: dto.archived ? new Date() : null }
          : {}),
      },
    });
  }

  async softDelete(userId: string, id: string): Promise<void> {
    await this.getOne(userId, id);
    await this.prisma.learningArea.update({
      where: { id },
      data: { archivedAt: new Date() },
    });
  }
}