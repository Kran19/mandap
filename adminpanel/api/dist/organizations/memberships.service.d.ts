import { PrismaService } from '../prisma.service.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto.js';
export declare class MembershipsService {
    private prisma;
    constructor(prisma: PrismaService);
    getMembers(organizationId: string): Promise<{
        userId: string;
        email: string;
        firstName: string | null;
        lastName: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
        role: import("@prisma/client").$Enums.MembershipRole;
        createdAt: Date;
    }[]>;
    addMember(organizationId: string, dto: AddMemberDto): Promise<{
        message: string;
        userId: string;
        role: import("@prisma/client").$Enums.MembershipRole;
    }>;
    updateMemberRole(organizationId: string, targetUserId: string, dto: UpdateMemberRoleDto): Promise<{
        message: string;
    }>;
    removeMember(organizationId: string, targetUserId: string): Promise<{
        message: string;
    }>;
    transferOwnership(organizationId: string, currentOwnerId: string, newOwnerId: string): Promise<{
        message: string;
    }>;
    leaveOrganization(organizationId: string, userId: string): Promise<{
        message: string;
    }>;
}
