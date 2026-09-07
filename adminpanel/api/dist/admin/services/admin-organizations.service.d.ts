import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminOrganizationQueryDto, AdminUpdateOrganizationDto } from '../dto/admin-organizations.dto.js';
export declare class AdminOrganizationsService {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    getOrganization(actorUserId: string, organizationId: string): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        memberCount: number;
        projectCount: number;
        createdAt: Date;
    }>;
    findAll(actorUserId: string, query: AdminOrganizationQueryDto): Promise<{
        data: {
            id: string;
            status: import("@prisma/client").$Enums.OrganizationStatus;
            createdAt: Date;
            name: string;
            slug: string;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    updateOrganization(actorUserId: string, organizationId: string, dto: AdminUpdateOrganizationDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        createdAt: Date;
        name: string;
        slug: string;
    }>;
}
