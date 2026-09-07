import { PrismaService } from '../../prisma.service.js';
import { AdminUsageQueryDto } from '../dto/admin-usage.dto.js';
export declare class AdminUsageService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findAll(actorId: string, query: AdminUsageQueryDto): Promise<{
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
