import { PrismaService } from '../../prisma.service.js';
import { Prisma } from '@prisma/client';
import { CreateProjectVersionDto } from '../validators/layout.validator.js';
export declare class ProjectVersionsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    createVersion(actorId: string, orgId: string, projectId: string, dto: CreateProjectVersionDto, idempotencyKey?: string): Promise<string | number | true | Prisma.JsonObject | Prisma.JsonArray | {
        id: string;
        createdAt: Date;
        metadata: Prisma.JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: Prisma.JsonValue | null;
    }>;
    restoreVersion(actorId: string, orgId: string, projectId: string, versionIdToRestore: string): Promise<{
        id: string;
        createdAt: Date;
        metadata: Prisma.JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: Prisma.JsonValue | null;
    }>;
    findHistory(orgId: string, projectId: string, page?: number, limit?: number): Promise<{
        data: {
            id: string;
            createdAt: Date;
            metadata: Prisma.JsonValue;
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
        metadata: Prisma.JsonValue | null;
        createdBy: string | null;
        versionNumber: number;
        projectId: string;
        layoutData: Prisma.JsonValue | null;
    }>;
}
