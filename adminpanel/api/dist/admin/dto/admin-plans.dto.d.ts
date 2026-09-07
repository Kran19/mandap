import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminPlanQueryDto extends PaginationDto {
    search?: string;
    status?: string;
}
export declare class AdminPlanFeatureDto {
    featureKey: string;
    enabled?: boolean;
}
export declare class AdminPlanLimitDto {
    key: string;
    limit: number;
}
export declare class AdminCreatePlanDto {
    name: string;
    slug: string;
    description?: string;
    monthlyPrice?: number;
    yearlyPrice?: number;
    currency?: string;
    status?: string;
    features?: AdminPlanFeatureDto[];
    limits?: AdminPlanLimitDto[];
}
export declare class AdminUpdatePlanDto {
    name?: string;
    description?: string;
    monthlyPrice?: number;
    yearlyPrice?: number;
    currency?: string;
    status?: string;
    features?: AdminPlanFeatureDto[];
    limits?: AdminPlanLimitDto[];
}
