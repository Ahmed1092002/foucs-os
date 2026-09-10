import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { StatisticsService } from './statistics.service';

interface AuthUser { id: string }
type Range = 'today' | 'week' | 'month' | 'all';

@ApiTags('statistics')
@ApiBearerAuth()
@Controller('stats')
@UseGuards(JwtAuthGuard)
export class StatisticsController {
  constructor(private readonly stats: StatisticsService) {}

  @Get('summary')
  @ApiOperation({ summary: 'Get summary statistics for a time range' })
  @ApiResponse({ status: 200, description: 'Summary stats' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  summary(
    @CurrentUser() user: AuthUser,
    @Query('range') range: Range = 'week',
  ) {
    return this.stats.summary(user.id, range);
  }

  @Get('by-subject')
  @ApiOperation({ summary: 'Get study time grouped by subject' })
  @ApiResponse({ status: 200, description: 'Subject breakdown' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  bySubject(
    @CurrentUser() user: AuthUser,
    @Query('range') range: Range = 'week',
  ) {
    return this.stats.bySubject(user.id, range);
  }

  @Get('by-day')
  @ApiOperation({ summary: 'Get study time grouped by day' })
  @ApiResponse({ status: 200, description: 'Daily breakdown' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  byDay(
    @CurrentUser() user: AuthUser,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.stats.byDay(user.id, from, to);
  }

  @Get('streak')
  @ApiOperation({ summary: 'Get current and longest learning streaks' })
  @ApiResponse({ status: 200, description: 'Streak data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  streak(@CurrentUser() user: AuthUser) {
    return this.stats.streak(user.id);
  }
}