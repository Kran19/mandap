import { IsEnum, IsOptional, IsString } from 'class-validator';
import { OrganizationStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminOrganizationQueryDto extends PaginationDto {
  @IsOptional()
  @IsEnum(OrganizationStatus)
  status?: OrganizationStatus;

  @IsOptional()
  @IsString()
  search?: string;
  
  @IsOptional()
  @IsString()
  slug?: string;
}

export class AdminUpdateOrganizationDto {
  @IsOptional()
  @IsEnum(OrganizationStatus)
  status?: OrganizationStatus;

  @IsOptional()
  @IsString()
  name?: string;
}
