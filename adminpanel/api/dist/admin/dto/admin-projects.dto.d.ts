import { ProjectStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminProjectQueryDto extends PaginationDto {
    search?: string;
    status?: ProjectStatus;
    organizationId?: string;
}
