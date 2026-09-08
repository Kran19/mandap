import { PrismaService } from '../../prisma.service.js';
import { AdminProjectQueryDto } from '../dto/admin-projects.dto.js';
export declare class AdminProjectsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findAll(actorId: string, query: AdminProjectQueryDto): Promise<{
        data: ({
            organization: {
                name: string;
                id: string;
                slug: string;
            };
            _count: {
                versions: number;
            };
        } & {
            name: string;
            id: string;
            status: import("@prisma/client").$Enums.ProjectStatus;
            createdAt: Date;
            updatedAt: Date;
            organizationId: string;
            description: string | null;
            currentVersionId: string | null;
            createdBy: string | null;
            archivedAt: Date | null;
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(actorId: string, projectId: string): Promise<{
        organization: {
            name: string;
            id: string;
            slug: string;
        };
        _count: {
            versions: number;
        };
        versions: {
            id: string;
            createdAt: Date;
            metadata: import("@prisma/client/runtime/library").JsonValue | null;
            createdBy: string | null;
            versionNumber: number;
            projectId: string;
            layoutData: import("@prisma/client/runtime/library").JsonValue | null;
        }[];
    } & {
        name: string;
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    findVersion(actorId: string, projectId: string, versionId: string): Promise<{
        id: string;
        createdAt: Date;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
}
