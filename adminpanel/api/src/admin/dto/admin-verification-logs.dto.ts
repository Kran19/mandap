import { IsOptional, IsString, IsEnum, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { VerificationChannel, VerificationStatus } from '@prisma/client';

export class AdminVerificationLogQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @IsOptional()
  @IsEnum(VerificationChannel)
  channel?: VerificationChannel;

  @IsOptional()
  @IsEnum(VerificationStatus)
  status?: VerificationStatus;

  @IsOptional()
  @IsString()
  search?: string;

  get skip(): number {
    return ((this.page || 1) - 1) * (this.limit || 20);
  }
}
