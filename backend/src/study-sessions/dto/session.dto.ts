import { Type } from 'class-transformer';
import {
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

const STATES = ['running', 'paused', 'completed', 'cancelled'] as const;
const GOAL_RESULTS = ['yes', 'partially', 'no'] as const;

/**
 * Client-issued `id` (UUID v4) — see docs/14-business-rules.md R-S17.
 * `startedAt` is the canonical timestamp — never trust the client clock
 * for ordering; we cap to now() +/- 1 minute on the server (R-S5).
 */
export class CreateSessionDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', format: 'uuid' })
  @IsUUID()
  id!: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440001', format: 'uuid' })
  @IsUUID()
  subjectId!: string;

  @ApiPropertyOptional({ example: 'useEffect deep dive', maxLength: 120 })
  @IsOptional() @IsString() @MaxLength(120) topic?: string;

  @ApiProperty({ example: 3600, minimum: 60, maximum: 28800, description: 'Planned duration in seconds (1 min to 8 hours)' })
  @Type(() => Number)
  @IsInt()
  @Min(60)
  @Max(60 * 60 * 8)
  plannedDurationSeconds!: number;

  @ApiProperty({ example: '2026-09-07T10:00:00.000Z', format: 'date-time' })
  @IsDateString()
  startedAt!: string;

  @ApiPropertyOptional({ example: "Understand when useEffect should and shouldn't be used", maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) goalText?: string;
}

export class UpdateSessionDto {
  @ApiPropertyOptional({ example: 'useEffect deep dive', maxLength: 120 })
  @IsOptional() @IsString() @MaxLength(120) topic?: string;

  @ApiPropertyOptional({ example: "Understand when useEffect should and shouldn't be used", maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) goalText?: string;

  @ApiPropertyOptional({ enum: STATES })
  @IsOptional() @IsIn([...STATES]) state?: typeof STATES[number];

  @ApiPropertyOptional({ example: 300, minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) pausedIntervalsSeconds?: number;

  @ApiPropertyOptional({ format: 'date-time' })
  @IsOptional() @IsDateString() endedAt?: string;

  @ApiPropertyOptional({ example: 3300, minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) actualDurationSeconds?: number;
}

export class CompleteSessionDto {
  @ApiProperty({ example: 3300, minimum: 0 })
  @Type(() => Number) @IsInt() @Min(0) actualDurationSeconds!: number;

  @ApiProperty({ example: 300, minimum: 0 })
  @Type(() => Number) @IsInt() @Min(0) pausedIntervalsSeconds!: number;

  @ApiProperty({ example: '2026-09-07T10:55:00.000Z', format: 'date-time' })
  @IsDateString() endedAt!: string;

  @ApiPropertyOptional({ enum: GOAL_RESULTS })
  @IsOptional() @IsIn([...GOAL_RESULTS]) goalResult?: typeof GOAL_RESULTS[number];

  @ApiPropertyOptional({ example: 4, minimum: 1, maximum: 5 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(5) focusRating?: number;

  @ApiPropertyOptional({ example: 3, minimum: 1, maximum: 5 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(5) energyRating?: number;

  @ApiPropertyOptional({ example: "Learned that useEffect should mainly synchronize with external systems.", maxLength: 2000 })
  @IsOptional() @IsString() @MaxLength(2000) notes?: string;
}

export const SessionState = Object.freeze(STATES);
export const GoalResult = Object.freeze(GOAL_RESULTS);