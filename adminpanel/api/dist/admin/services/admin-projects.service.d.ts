import { PrismaService } from '../../prisma.service.js';
import { AdminProjectQueryDto } from '../dto/admin-projects.dto.js';
export declare class AdminProjectsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findAll(actorId: string, query: AdminProjectQueryDto): Promise<{
        data: ({
            organization: {
                id: string;
                name: string;
                slug: string;
            };
            _count: {
                versions: number;
            };
        } & {
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
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(actorId: string, projectId: string): Promise<{
        organization: {
            id: string;
            name: string;
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
