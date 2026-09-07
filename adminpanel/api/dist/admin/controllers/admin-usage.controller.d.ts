import { AdminUsageService } from '../services/admin-usage.service.js';
import { AdminUsageQueryDto } from '../dto/admin-usage.dto.js';
export declare class AdminUsageController {
    private readonly usageService;
    constructor(usageService: AdminUsageService);
    findAll(actor: any, query: AdminUsageQueryDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            organizationId: string;
            value: number;
            metric: string;
            periodStart: Date | null;
            periodEnd: Date | null;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findByOrg(actor: any, orgId: string, query: AdminUsageQueryDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            organizationId: string;
            value: number;
            metric: string;
            periodStart: Date | null;
            periodEnd: Date | null;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
}
