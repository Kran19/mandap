import { IsEnum, IsOptional, IsString } from 'class-validator';
import { MembershipRole } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminMembershipQueryDto extends PaginationDto {
  @IsOptional()
  @IsEnum(MembershipRole)
  role?: MembershipRole;

  @IsOptional()
  @IsString()
  userId?: string;
}

export class AdminAddMembershipDto {
  @IsString()
  userId: string;

  @IsEnum(MembershipRole)
  role: MembershipRole;
}

export class AdminUpdateMembershipDto {
  @IsEnum(MembershipRole)
  role: MembershipRole;
}
