import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminUsageQueryDto extends PaginationDto {
    organizationId?: string;
    metricName?: string;
}
