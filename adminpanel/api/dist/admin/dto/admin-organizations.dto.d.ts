import { OrganizationStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminOrganizationQueryDto extends PaginationDto {
    status?: OrganizationStatus;
    search?: string;
    slug?: string;
}
export declare class AdminUpdateOrganizationDto {
    status?: OrganizationStatus;
    name?: string;
}
