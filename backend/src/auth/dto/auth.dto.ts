import { IsEmail, IsString, MinLength, MaxLength, Matches, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SignupDto {
  @ApiProperty({ example: 'dev@example.com', description: 'User email' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'hunter22long', description: 'Password (min 8 chars)' })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @ApiPropertyOptional({ example: 'Africa/Cairo', description: 'IANA timezone' })
  @IsOptional()
  @IsString()
  @Matches(/^[A-Za-z_]+(?:\/[A-Za-z_]+)*$/, { message: 'timezone must be an IANA zone like Africa/Cairo' })
  timezone?: string;
}

export class LoginDto {
  @ApiProperty({ example: 'dev@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'hunter22long' })
  @IsString()
  @MinLength(1)
  password!: string;
}

export class RefreshDto {
  @ApiProperty({ description: 'Refresh token from login/signup response' })
  @IsString()
  @MinLength(1)
  refreshToken!: string;
}