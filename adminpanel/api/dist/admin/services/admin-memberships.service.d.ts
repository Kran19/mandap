import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminMembershipQueryDto, AdminAddMembershipDto, AdminUpdateMembershipDto } from '../dto/admin-memberships.dto.js';
export declare class AdminMembershipsService {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    findAll(actorId: string, orgId: string, query: AdminMembershipQueryDto): Promise<{
        data: ({
            user: {
                email: string | null;
                id: string;
                status: import("@prisma/client").$Enums.UserStatus;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            role: import("@prisma/client").$Enums.MembershipRole;
            organizationId: string;
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    addMember(actorId: string, orgId: string, dto: AdminAddMembershipDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        role: import("@prisma/client").$Enums.MembershipRole;
        organizationId: string;
    }>;
    updateMemberRole(actorId: string, orgId: string, userId: string, dto: AdminUpdateMembershipDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        role: import("@prisma/client").$Enums.MembershipRole;
        organizationId: string;
    }>;
    removeMember(actorId: string, orgId: string, userId: string): Promise<{
        success: boolean;
    }>;
}
