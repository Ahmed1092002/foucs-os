import { Body, Controller, Get, Param, Put, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DailyReviewsService } from './daily-reviews.service';
import { UpsertReviewDto } from './dto/review.dto';

interface AuthUser { id: string }

@ApiTags('reviews')
@ApiBearerAuth()
@Controller('reviews')
@UseGuards(JwtAuthGuard)
export class DailyReviewsController {
  constructor(private readonly reviews: DailyReviewsService) {}

  @Get()
  @ApiOperation({ summary: 'List daily reviews in a date range' })
  @ApiResponse({ status: 200, description: 'List of daily reviews' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(
    @CurrentUser() user: AuthUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.reviews.list(user.id, from, to);
  }

  @Get(':date')
  @ApiOperation({ summary: 'Get daily review for a specific date' })
  @ApiResponse({ status: 200, description: 'Daily review details' })
  @ApiResponse({ status: 404, description: 'Review not found' })
  getForDate(@CurrentUser() user: AuthUser, @Param('date') date: string) {
    return this.reviews.getForDate(user.id, date);
  }

  @Put(':date')
  @ApiOperation({ summary: 'Create or update daily review for a date' })
  @ApiResponse({ status: 200, description: 'Review created/updated' })
  @ApiResponse({ status: 400, description: 'Validation error' })
  upsert(
    @CurrentUser() user: AuthUser,
    @Param('date') date: string,
    @Body() dto: UpsertReviewDto,
  ) {
    return this.reviews.upsert(user.id, date, dto);
  }
}