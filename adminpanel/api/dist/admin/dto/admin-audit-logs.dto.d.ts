import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminAuditLogQueryDto extends PaginationDto {
    actorUserId?: string;
    action?: string;
    resourceType?: string;
    resourceId?: string;
}
