import {
  Body,
  Controller,
  Delete,
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
import { CoursesService } from './courses.service';
import {
  CreateCourseDto,
  CreateLessonDto,
  CreateModuleDto,
  UpdateCourseDto,
  UpdateLessonDto,
  UpdateModuleDto,
} from './dto/course.dto';

interface AuthUser { id: string }

// ---- Courses ----

@ApiTags('courses')
@ApiBearerAuth()
@Controller('courses')
@UseGuards(JwtAuthGuard)
export class CoursesController {
  constructor(private readonly courses: CoursesService) {}

  @Get()
  @ApiOperation({ summary: 'List all courses' })
  @ApiResponse({ status: 200, description: 'List of courses' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(@CurrentUser() user: AuthUser, @Query('subjectId') subjectId?: string) {
    return this.courses.list(user.id, subjectId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single course by ID' })
  @ApiResponse({ status: 200, description: 'Course details with modules and lessons' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  getOne(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.courses.getOne(user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new course' })
  @ApiResponse({ status: 201, description: 'Course created' })
  @ApiResponse({ status: 400, description: 'Validation error' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateCourseDto) {
    return this.courses.create(user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a course' })
  @ApiResponse({ status: 200, description: 'Course updated' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateCourseDto,
  ) {
    return this.courses.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a course' })
  @ApiResponse({ status: 204, description: 'Course deleted' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  async remove(@CurrentUser() user: AuthUser, @Param('id') id: string): Promise<void> {
    await this.courses.remove(user.id, id);
  }

  // ---- Modules nested under a course ----

  @Get(':id/modules')
  @ApiOperation({ summary: 'List modules for a course' })
  @ApiResponse({ status: 200, description: 'List of modules' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  listModules(@CurrentUser() user: AuthUser, @Param('id') courseId: string) {
    return this.courses.listModules(user.id, courseId);
  }

  @Post(':id/modules')
  @ApiOperation({ summary: 'Add a module to a course' })
  @ApiResponse({ status: 201, description: 'Module created' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  addModule(
    @CurrentUser() user: AuthUser,
    @Param('id') courseId: string,
    @Body() dto: CreateModuleDto,
  ) {
    return this.courses.addModule(user.id, courseId, dto);
  }

  @Patch(':id/modules/:moduleId')
  @ApiOperation({ summary: 'Update a module' })
  @ApiResponse({ status: 200, description: 'Module updated' })
  @ApiResponse({ status: 404, description: 'Module not found' })
  updateModule(
    @CurrentUser() user: AuthUser,
    @Param('id') courseId: string,
    @Param('moduleId') moduleId: string,
    @Body() dto: UpdateModuleDto,
  ) {
    return this.courses.updateModule(user.id, courseId, moduleId, dto);
  }

  @Delete(':id/modules/:moduleId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a module' })
  @ApiResponse({ status: 204, description: 'Module deleted' })
  @ApiResponse({ status: 404, description: 'Module not found' })
  async removeModule(
    @CurrentUser() user: AuthUser,
    @Param('id') courseId: string,
    @Param('moduleId') moduleId: string,
  ): Promise<void> {
    await this.courses.removeModule(user.id, courseId, moduleId);
  }

  // ---- Lessons nested under a module ----

  @Get(':id/modules/:moduleId/lessons')
  @ApiOperation({ summary: 'List lessons for a module' })
  @ApiResponse({ status: 200, description: 'List of lessons' })
  @ApiResponse({ status: 404, description: 'Module not found' })
  listLessons(
    @CurrentUser() user: AuthUser,
    @Param('moduleId') moduleId: string,
  ) {
    return this.courses.listLessons(user.id, moduleId);
  }

  @Post(':id/modules/:moduleId/lessons')
  @ApiOperation({ summary: 'Add a lesson to a module' })
  @ApiResponse({ status: 201, description: 'Lesson created' })
  @ApiResponse({ status: 404, description: 'Module not found' })
  addLesson(
    @CurrentUser() user: AuthUser,
    @Param('moduleId') moduleId: string,
    @Body() dto: CreateLessonDto,
  ) {
    return this.courses.addLesson(user.id, moduleId, dto);
  }

  @Patch(':id/modules/:moduleId/lessons/:lessonId')
  @ApiOperation({ summary: 'Update a lesson' })
  @ApiResponse({ status: 200, description: 'Lesson updated' })
  @ApiResponse({ status: 404, description: 'Lesson not found' })
  updateLesson(
    @CurrentUser() user: AuthUser,
    @Param('moduleId') moduleId: string,
    @Param('lessonId') lessonId: string,
    @Body() dto: UpdateLessonDto,
  ) {
    return this.courses.updateLesson(user.id, moduleId, lessonId, dto);
  }

  @Delete(':id/modules/:moduleId/lessons/:lessonId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a lesson' })
  @ApiResponse({ status: 204, description: 'Lesson deleted' })
  @ApiResponse({ status: 404, description: 'Lesson not found' })
  async removeLesson(
    @CurrentUser() user: AuthUser,
    @Param('moduleId') moduleId: string,
    @Param('lessonId') lessonId: string,
  ): Promise<void> {
    await this.courses.removeLesson(user.id, moduleId, lessonId);
  }
}

// Separate controller for the progress endpoint, mounted under subjects
@ApiTags('courses')
@ApiBearerAuth()
@Controller('subjects')
@UseGuards(JwtAuthGuard)
export class SubjectProgressController {
  constructor(private readonly courses: CoursesService) {}

  @Get(':id/progress')
  @ApiOperation({ summary: 'Get subject learning progress' })
  @ApiResponse({ status: 200, description: 'Progress summary' })
  @ApiResponse({ status: 404, description: 'Subject not found' })
  progress(@CurrentUser() user: AuthUser, @Param('id') subjectId: string) {
    return this.courses.subjectProgress(user.id, subjectId);
  }
}