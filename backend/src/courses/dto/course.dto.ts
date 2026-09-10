import { Type } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

const LESSON_STATUSES = ['not_started', 'in_progress', 'completed'] as const;

export class CreateCourseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440001', format: 'uuid' })
  @IsUUID()
  subjectId!: string;

  @ApiProperty({ example: 'Advanced React', minLength: 1, maxLength: 120 })
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({ example: 'Deep dive into React patterns', maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;
}

export class UpdateCourseDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: 120 })
  @IsOptional() @IsString() @MinLength(1) @MaxLength(120) name?: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;
}

export class CreateModuleDto {
  @ApiProperty({ example: 'Hooks', minLength: 1, maxLength: 120 })
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({ example: 'useEffect, useMemo, useCallback', maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;

  @ApiPropertyOptional({ example: 0, minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) orderIndex?: number;
}

export class UpdateModuleDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: 120 })
  @IsOptional() @IsString() @MinLength(1) @MaxLength(120) name?: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) orderIndex?: number;
}

export class CreateLessonDto {
  @ApiProperty({ example: 'useEffect Deep Dive', minLength: 1, maxLength: 120 })
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({ example: 'When and why to use useEffect', maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) orderIndex?: number;
}

export class UpdateLessonDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: 120 })
  @IsOptional() @IsString() @MinLength(1) @MaxLength(120) name?: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) orderIndex?: number;

  @ApiPropertyOptional({ enum: LESSON_STATUSES })
  @IsOptional() @IsIn([...LESSON_STATUSES]) status?: typeof LESSON_STATUSES[number];
}

class LessonOrderItem {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440002', format: 'uuid' })
  @IsUUID()
  id!: string;

  @ApiProperty({ example: 0, minimum: 0 })
  @Type(() => Number) @IsInt() @Min(0) orderIndex!: number;
}

export class ReorderLessonsDto {
  @ApiProperty({ type: [LessonOrderItem] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LessonOrderItem)
  items!: LessonOrderItem[];
}

export const LessonStatuses = Object.freeze(LESSON_STATUSES);