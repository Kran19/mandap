import { AdminAuditLogsService } from '../services/admin-audit-logs.service.js';
import { AdminAuditLogQueryDto } from '../dto/admin-audit-logs.dto.js';
export declare class AdminAuditLogsController {
    private readonly auditLogsService;
    constructor(auditLogsService: AdminAuditLogsService);
    findAll(query: AdminAuditLogQueryDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            ipAddress: string | null;
            userAgent: string | null;
            organizationId: string | null;
            action: string;
            metadata: import("@prisma/client/runtime/library").JsonValue | null;
            adminId: string | null;
            actorUserId: string | null;
            resourceType: string;
            resourceId: string | null;
            before: import("@prisma/client/runtime/library").JsonValue | null;
            after: import("@prisma/client/runtime/library").JsonValue | null;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(id: string): Promise<{
        id: string;
        createdAt: Date;
        ipAddress: string | null;
        userAgent: string | null;
        organizationId: string | null;
        action: string;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        adminId: string | null;
        actorUserId: string | null;
        resourceType: string;
        resourceId: string | null;
        before: import("@prisma/client/runtime/library").JsonValue | null;
        after: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
}
