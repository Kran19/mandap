import { IsEnum, IsOptional, IsString } from 'class-validator';
import { UserStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminUserQueryDto extends PaginationDto {
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;

  @IsOptional()
  @IsString()
  search?: string;
}

export class AdminUpdateUserDto {
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}
