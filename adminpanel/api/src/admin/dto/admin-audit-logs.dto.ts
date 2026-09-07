import { IsOptional, IsString } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class AdminAuditLogQueryDto extends PaginationDto {
  @IsOptional()
  @IsString()
  actorUserId?: string;

  @IsOptional()
  @IsString()
  action?: string;

  @IsOptional()
  @IsString()
  resourceType?: string;
  
  @IsOptional()
  @IsString()
  resourceId?: string;
}
