import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PlanItemDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440001', format: 'uuid' })
  @IsUUID()
  subjectId!: string;

  /** HH:MM 24-hour, e.g. "09:30" */
  @ApiProperty({ example: '09:30', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'startTime must be HH:MM' })
  startTime!: string;

  @ApiProperty({ example: 3600, minimum: 60, maximum: 28800 })
  @Type(() => Number)
  @IsInt()
  @Min(60)
  @Max(60 * 60 * 8)
  durationSeconds!: number;

  @ApiPropertyOptional({ example: 0, minimum: 0 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) orderIndex?: number;
}

export class ReplacePlanDto {
  @ApiProperty({ type: [PlanItemDto] })
  @IsArray()
  @ArrayMinSize(0)
  @ValidateNested({ each: true })
  @Type(() => PlanItemDto)
  items!: PlanItemDto[];
}