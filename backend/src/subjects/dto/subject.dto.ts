import { Type } from 'class-transformer';
import { IsDateString, IsHexColor, IsInt, IsNumber, IsOptional, IsString, IsUUID, Matches, Max, MaxLength, Min, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateSubjectDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', format: 'uuid' })
  @IsUUID()
  areaId!: string;

  @ApiProperty({ example: 'React', minLength: 1, maxLength: 64 })
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  name!: string;

  @ApiPropertyOptional({ example: 'Learn React hooks and patterns', maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;

  @ApiPropertyOptional({ example: '#61DAFB', pattern: '^#[0-9A-Fa-f]{6}$' })
  @IsOptional() @IsString() @Matches(/^#[0-9A-Fa-f]{6}$/) color?: string;

  @ApiPropertyOptional({ example: 40, minimum: 0 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  targetHours: number = 0;

  @ApiPropertyOptional({ example: 1, minimum: 0, maximum: 3 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(3) priority?: number;

  @ApiPropertyOptional({ example: '2026-12-31', format: 'date' })
  @IsOptional() @IsDateString() deadline?: string;
}

export class UpdateSubjectDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: 64 })
  @IsOptional() @IsString() @MinLength(1) @MaxLength(64) name?: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional() @IsString() @MaxLength(500) description?: string;

  @ApiPropertyOptional({ pattern: '^#[0-9A-Fa-f]{6}$' })
  @IsOptional() @IsString() @Matches(/^#[0-9A-Fa-f]{6}$/) color?: string;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) targetHours?: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 3 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(3) priority?: number;

  @ApiPropertyOptional({ format: 'date' })
  @IsOptional() @IsDateString() deadline?: string;

  @ApiPropertyOptional({ example: 'in-progress' })
  @IsOptional() @IsString() status?: string;
}