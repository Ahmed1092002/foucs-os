import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SessionsService } from './sessions.service';
import {
  CompleteSessionDto,
  CreateSessionDto,
  UpdateSessionDto,
} from './dto/session.dto';

interface AuthUser { id: string }

@ApiTags('sessions')
@ApiBearerAuth()
@Controller('sessions')
@UseGuards(JwtAuthGuard)
export class SessionsController {
  constructor(private readonly sessions: SessionsService) {}

  @Get()
  @ApiOperation({ summary: 'List study sessions with filters' })
  @ApiResponse({ status: 200, description: 'Paginated list of sessions' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(
    @CurrentUser() user: AuthUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('subjectId') subjectId?: string,
    @Query('areaId') areaId?: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.sessions.list(user.id, {
      from: from ? new Date(from) : undefined,
      to: to ? new Date(to) : undefined,
      subjectId,
      areaId,
      cursor,
      limit: limit ? Number.parseInt(limit, 10) : undefined,
    });
  }

  @Get('active')
  @ApiOperation({ summary: 'Get the currently active session' })
  @ApiResponse({ status: 200, description: 'Active session or null' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  active(@CurrentUser() user: AuthUser) {
    return this.sessions.getActive(user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Start a new study session' })
  @ApiResponse({ status: 201, description: 'Session created' })
  @ApiResponse({ status: 400, description: 'Validation error' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateSessionDto) {
    return this.sessions.create(user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a session (pause/resume)' })
  @ApiResponse({ status: 200, description: 'Session updated' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateSessionDto,
  ) {
    return this.sessions.update(user.id, id, dto);
  }

  @Post(':id/complete')
  @ApiOperation({ summary: 'Complete a study session' })
  @ApiResponse({ status: 200, description: 'Session completed with summary' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  complete(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: CompleteSessionDto,
  ) {
    return this.sessions.complete(user.id, id, dto);
  }

  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel a study session' })
  @ApiResponse({ status: 200, description: 'Session cancelled' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  cancel(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.sessions.cancel(user.id, id);
  }
}