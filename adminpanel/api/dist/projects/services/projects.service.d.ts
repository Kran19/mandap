import { PrismaService } from '../../prisma.service.js';
import { EntitlementService } from '../../billing/services/entitlement.service.js';
import { Prisma } from '@prisma/client';
export declare class CreateProjectDto {
    name: string;
    description?: string;
    organizationId: string;
}
export declare class UpdateProjectDto {
    name?: string;
    description?: string;
}
export declare class ProjectsService {
    private readonly prisma;
    private readonly entitlementService;
    constructor(prisma: PrismaService, entitlementService: EntitlementService);
    create(actorId: string, orgId: string, dto: CreateProjectDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    findAll(orgId: string, page?: number, limit?: number): Promise<{
        data: {
            id: string;
            status: import("@prisma/client").$Enums.ProjectStatus;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            organizationId: string;
            description: string | null;
            currentVersionId: string | null;
            createdBy: string | null;
            archivedAt: Date | null;
        }[];
        meta: {
            total: number;
            page: number;
            limit: number;
        };
    }>;
    findOne(orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    update(actorId: string, orgId: string, projectId: string, dto: UpdateProjectDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    archive(actorId: string, orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    restore(actorId: string, orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    remove(actorId: string, orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    private upsertProjectsUsage;
    logCustomerAudit(tx: Prisma.TransactionClient, actorUserId: string, organizationId: string, action: string, resourceType: string, resourceId?: string, before?: any, after?: any): Promise<void>;
}
