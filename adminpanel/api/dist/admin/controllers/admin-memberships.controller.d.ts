import { AdminMembershipsService } from '../services/admin-memberships.service.js';
import { AdminMembershipQueryDto, AdminAddMembershipDto, AdminUpdateMembershipDto } from '../dto/admin-memberships.dto.js';
export declare class AdminMembershipsController {
    private readonly membershipsService;
    constructor(membershipsService: AdminMembershipsService);
    findAll(actor: any, orgId: string, query: AdminMembershipQueryDto): Promise<{
        data: ({
            user: {
                email: string;
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
    addMember(actor: any, orgId: string, dto: AdminAddMembershipDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        role: import("@prisma/client").$Enums.MembershipRole;
        organizationId: string;
    }>;
    updateMemberRole(actor: any, orgId: string, userId: string, dto: AdminUpdateMembershipDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        role: import("@prisma/client").$Enums.MembershipRole;
        organizationId: string;
    }>;
    removeMember(actor: any, orgId: string, userId: string): Promise<{
        success: boolean;
    }>;
}
