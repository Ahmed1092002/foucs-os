import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, ParseBoolPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AreasService } from './areas.service';
import { CreateAreaDto, UpdateAreaDto } from './dto/area.dto';

interface AuthUser { id: string }

@ApiTags('areas')
@ApiBearerAuth()
@Controller('areas')
@UseGuards(JwtAuthGuard)
export class AreasController {
  constructor(private readonly areas: AreasService) {}

  @Get()
  @ApiOperation({ summary: 'List all learning areas' })
  @ApiResponse({ status: 200, description: 'List of areas' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(
    @CurrentUser() user: AuthUser,
    @Query('includeArchived') includeArchived?: string,
  ) {
    const flag = includeArchived === 'true' || includeArchived === '1';
    return this.areas.list(user.id, flag);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single learning area by ID' })
  @ApiResponse({ status: 200, description: 'Area details' })
  @ApiResponse({ status: 404, description: 'Area not found' })
  getOne(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.areas.getOne(user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new learning area' })
  @ApiResponse({ status: 201, description: 'Area created' })
  @ApiResponse({ status: 400, description: 'Validation error' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateAreaDto) {
    return this.areas.create(user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a learning area' })
  @ApiResponse({ status: 200, description: 'Area updated' })
  @ApiResponse({ status: 404, description: 'Area not found' })
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateAreaDto) {
    return this.areas.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Soft delete a learning area' })
  @ApiResponse({ status: 204, description: 'Area deleted' })
  @ApiResponse({ status: 404, description: 'Area not found' })
  async remove(@CurrentUser() user: AuthUser, @Param('id') id: string): Promise<void> {
    await this.areas.softDelete(user.id, id);
  }
}