import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DailyPlansService } from './daily-plans.service';
import { ReplacePlanDto } from './dto/plan.dto';

interface AuthUser { id: string }

@ApiTags('plans')
@ApiBearerAuth()
@Controller('plans')
@UseGuards(JwtAuthGuard)
export class DailyPlansController {
  constructor(private readonly plans: DailyPlansService) {}

  @Get()
  @ApiOperation({ summary: 'List daily plans in a date range' })
  @ApiResponse({ status: 200, description: 'List of daily plans' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(
    @CurrentUser() user: AuthUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.plans.list(user.id, from, to);
  }

  @Get(':date')
  @ApiOperation({ summary: 'Get daily plan for a specific date' })
  @ApiResponse({ status: 200, description: 'Daily plan with items' })
  @ApiResponse({ status: 404, description: 'Plan not found' })
  getForDate(@CurrentUser() user: AuthUser, @Param('date') date: string) {
    return this.plans.getForDate(user.id, date);
  }

  @Put(':date')
  @ApiOperation({ summary: 'Replace (create or update) daily plan for a date' })
  @ApiResponse({ status: 200, description: 'Plan created/updated' })
  @ApiResponse({ status: 400, description: 'Validation error' })
  replace(
    @CurrentUser() user: AuthUser,
    @Param('date') date: string,
    @Body() dto: ReplacePlanDto,
  ) {
    return this.plans.replace(user.id, date, dto);
  }

  @Delete(':date')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a daily plan' })
  @ApiResponse({ status: 204, description: 'Plan deleted' })
  @ApiResponse({ status: 404, description: 'Plan not found' })
  async remove(@CurrentUser() user: AuthUser, @Param('date') date: string): Promise<void> {
    await this.plans.remove(user.id, date);
  }
}