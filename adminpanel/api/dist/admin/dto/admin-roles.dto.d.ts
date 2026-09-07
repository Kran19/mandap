import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminRoleQueryDto extends PaginationDto {
    search?: string;
}
export declare class AdminCreateRoleDto {
    name: string;
    description?: string;
    permissions: string[];
}
export declare class AdminUpdateRoleDto {
    description?: string;
    isActive?: boolean;
    permissions?: string[];
}
