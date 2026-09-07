import { ProjectVersionsService } from '../services/project-versions.service.js';
import { CreateProjectVersionDto } from '../validators/layout.validator.js';
export declare class ProjectVersionsController {
    private readonly projectVersionsService;
    constructor(projectVersionsService: ProjectVersionsService);
    create(user: any, orgId: string, projectId: string, dto: CreateProjectVersionDto, idempotencyKey?: string): Promise<string | number | true | import("@prisma/client/runtime/library").JsonObject | import("@prisma/client/runtime/library").JsonArray | {
        id: string;
        createdAt: Date;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    restore(user: any, orgId: string, projectId: string, versionId: string): Promise<{
        id: string;
        createdAt: Date;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    findAll(orgId: string, projectId: string, page?: string, limit?: string): Promise<{
        data: {
            id: string;
            createdAt: Date;
            metadata: import("@prisma/client/runtime/library").JsonValue;
            createdBy: string | null;
            versionNumber: number;
            projectId: string;
        }[];
        meta: {
            total: number;
            page: number;
            limit: number;
        };
    }>;
    findOne(orgId: string, projectId: string, versionId: string): Promise<{
        id: string;
        createdAt: Date;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
}
