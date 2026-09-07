import { IsBoolean, IsOptional, IsString, IsArray } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminRoleQueryDto extends PaginationDto {
  @IsOptional()
  @IsString()
  search?: string;
}

export class AdminCreateRoleDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsArray()
  @IsString({ each: true })
  permissions: string[];
}

export class AdminUpdateRoleDto {
  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  permissions?: string[];
}
