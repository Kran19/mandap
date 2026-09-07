import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminFeatureFlagQueryDto extends PaginationDto {
    search?: string;
    isActive?: boolean;
}
export declare class AdminCreateFeatureFlagDto {
    key: string;
    name: string;
    description?: string;
    isActive?: boolean;
}
export declare class AdminUpdateFeatureFlagDto {
    name?: string;
    description?: string;
    isActive?: boolean;
}
