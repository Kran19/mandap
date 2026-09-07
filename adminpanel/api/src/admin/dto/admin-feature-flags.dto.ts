import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminFeatureFlagQueryDto extends PaginationDto {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class AdminCreateFeatureFlagDto {
  @IsString()
  key: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class AdminUpdateFeatureFlagDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
