import { IsOptional, IsString, IsInt, Min, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';

export class AdminBillingQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 10;

  @IsOptional()
  @IsString()
  search?: string;

  get skip(): number {
    return ((this.page || 1) - 1) * (this.limit || 10);
  }
}

export class AdminRefundDto {
  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  reason?: string;
}
