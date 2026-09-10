import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SubjectsService } from './subjects.service';
import { CreateSubjectDto, UpdateSubjectDto } from './dto/subject.dto';

interface AuthUser { id: string }

@ApiTags('subjects')
@ApiBearerAuth()
@Controller('subjects')
@UseGuards(JwtAuthGuard)
export class SubjectsController {
  constructor(private readonly subjects: SubjectsService) {}

  @Get()
  @ApiOperation({ summary: 'List all subjects' })
  @ApiResponse({ status: 200, description: 'List of subjects' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(
    @CurrentUser() user: AuthUser,
    @Query('areaId') areaId?: string,
    @Query('status') status?: string,
  ) {
    return this.subjects.list(user.id, areaId, status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single subject by ID' })
  @ApiResponse({ status: 200, description: 'Subject details' })
  @ApiResponse({ status: 404, description: 'Subject not found' })
  getOne(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.subjects.getOne(user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new subject' })
  @ApiResponse({ status: 201, description: 'Subject created' })
  @ApiResponse({ status: 400, description: 'Validation error' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateSubjectDto) {
    return this.subjects.create(user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a subject' })
  @ApiResponse({ status: 200, description: 'Subject updated' })
  @ApiResponse({ status: 404, description: 'Subject not found' })
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateSubjectDto) {
    return this.subjects.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Soft delete a subject' })
  @ApiResponse({ status: 204, description: 'Subject deleted' })
  @ApiResponse({ status: 404, description: 'Subject not found' })
  async remove(@CurrentUser() user: AuthUser, @Param('id') id: string): Promise<void> {
    await this.subjects.softDelete(user.id, id);
  }
}