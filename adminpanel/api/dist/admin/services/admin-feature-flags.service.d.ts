import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminFeatureFlagQueryDto, AdminCreateFeatureFlagDto, AdminUpdateFeatureFlagDto } from '../dto/admin-feature-flags.dto.js';
export declare class AdminFeatureFlagsService {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    findAll(actorId: string, query: AdminFeatureFlagQueryDto): Promise<{
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
    findOne(actorId: string, flagId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        enabled: boolean;
        key: string;
    }>;
    createFeatureFlag(actorId: string, dto: AdminCreateFeatureFlagDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        enabled: boolean;
        key: string;
    }>;
    updateFeatureFlag(actorId: string, flagId: string, dto: AdminUpdateFeatureFlagDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        enabled: boolean;
        key: string;
    }>;
}
