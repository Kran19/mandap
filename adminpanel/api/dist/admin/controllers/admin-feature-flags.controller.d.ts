import { AdminFeatureFlagsService } from '../services/admin-feature-flags.service.js';
import { AdminFeatureFlagQueryDto, AdminCreateFeatureFlagDto, AdminUpdateFeatureFlagDto } from '../dto/admin-feature-flags.dto.js';
export declare class AdminFeatureFlagsController {
    private readonly featureFlagsService;
    constructor(featureFlagsService: AdminFeatureFlagsService);
    findAll(actor: any, query: AdminFeatureFlagQueryDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            description: string | null;
            enabled: boolean;
            key: string;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(actor: any, id: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        enabled: boolean;
        key: string;
    }>;
    createFeatureFlag(actor: any, dto: AdminCreateFeatureFlagDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        enabled: boolean;
        key: string;
    }>;
    updateFeatureFlag(actor: any, id: string, dto: AdminUpdateFeatureFlagDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        enabled: boolean;
        key: string;
    }>;
}
