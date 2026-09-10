import { IsHexColor, IsOptional, IsString, MaxLength, MinLength, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateAreaDto {
  @ApiProperty({ example: 'Frontend', minLength: 1, maxLength: 64 })
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  name!: string;

  @ApiProperty({ example: '#5B8DEF', pattern: '^#[0-9A-Fa-f]{6}$' })
  @IsString()
  @Matches(/^#[0-9A-Fa-f]{6}$/, { message: 'color must be a 6-digit hex like #5B8DEF' })
  color!: string;

  @ApiPropertyOptional({ example: 'code', maxLength: 32 })
  @IsOptional()
  @IsString()
  @MaxLength(32)
  icon?: string;
}

export class UpdateAreaDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: 64 })
  @IsOptional() @IsString() @MinLength(1) @MaxLength(64) name?: string;

  @ApiPropertyOptional({ pattern: '^#[0-9A-Fa-f]{6}$' })
  @IsOptional() @IsString() @Matches(/^#[0-9A-Fa-f]{6}$/) color?: string;

  @ApiPropertyOptional({ maxLength: 32 })
  @IsOptional() @IsString() @MaxLength(32) icon?: string;

  @ApiPropertyOptional({ example: false })
  @IsOptional() archived?: boolean;
}