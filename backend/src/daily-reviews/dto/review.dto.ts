import { Type } from 'class-transformer';
import { IsDateString, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpsertReviewDto {
  @ApiPropertyOptional({ example: 4, minimum: 1, maximum: 5 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(5) productivityRating?: number;

  @ApiPropertyOptional({ example: 3, minimum: 1, maximum: 5 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(5) energyRating?: number;

  @ApiPropertyOptional({ example: 5, minimum: 1, maximum: 5 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(5) focusRating?: number;

  @ApiPropertyOptional({ example: 'Completed React hooks deep dive', maxLength: 2000 })
  @IsOptional() @IsString() @MaxLength(2000) wentWell?: string;

  @ApiPropertyOptional({ example: 'Blocked by missing docs', maxLength: 2000 })
  @IsOptional() @IsString() @MaxLength(2000) blockedBy?: string;
}

/** Path param shape (validated in service). */
export class ReviewDateParam {
  @ApiProperty({ example: '2026-09-07', format: 'date' })
  @IsDateString()
  date!: string;
}