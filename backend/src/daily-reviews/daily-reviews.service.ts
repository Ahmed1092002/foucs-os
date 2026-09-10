import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertReviewDto } from './dto/review.dto';

function parseDate(s: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    throw new BadRequestException('date must be YYYY-MM-DD');
  }
  const d = new Date(s + 'T00:00:00Z');
  if (Number.isNaN(d.getTime())) {
    throw new BadRequestException('Invalid date');
  }
  return d;
}

@Injectable()
export class DailyReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, from?: string, to?: string) {
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

  async getForDate(userId: string, date: string) {
    const reviewDate = parseDate(date);
    return this.prisma.dailyReview.findUnique({
      where: { userId_reviewDate: { userId, reviewDate } },
    });
  }

  async upsert(userId: string, date: string, dto: UpsertReviewDto) {
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
}