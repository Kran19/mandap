import { IsOptional, IsString, IsNumber, IsBoolean, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminPlanQueryDto extends PaginationDto {
  @IsOptional()
  @IsString()
  search?: string;
  
  @IsOptional()
  @IsString()
  status?: string;
}

export class AdminPlanFeatureDto {
  @IsString()
  featureKey: string;

  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}

export class AdminPlanLimitDto {
  @IsString()
  key: string;

  @IsNumber()
  limit: number;
}

export class AdminCreatePlanDto {
  @IsString()
  name: string;

  @IsString()
  slug: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsNumber()
  monthlyPrice?: number;

  @IsOptional()
  @IsNumber()
  yearlyPrice?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AdminPlanFeatureDto)
  features?: AdminPlanFeatureDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AdminPlanLimitDto)
  limits?: AdminPlanLimitDto[];
}

export class AdminUpdatePlanDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsNumber()
  monthlyPrice?: number;

  @IsOptional()
  @IsNumber()
  yearlyPrice?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AdminPlanFeatureDto)
  features?: AdminPlanFeatureDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AdminPlanLimitDto)
  limits?: AdminPlanLimitDto[];
}
