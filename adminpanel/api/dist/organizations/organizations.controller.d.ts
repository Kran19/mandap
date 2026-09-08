import { OrganizationsService } from './organizations.service.js';
import { MembershipsService } from './memberships.service.js';
import { CreateOrganizationDto } from './dto/create-organization.dto.js';
import { UpdateOrganizationDto } from './dto/update-organization.dto.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto.js';
import { TransferOwnershipDto } from './dto/transfer-ownership.dto.js';
export declare class OrganizationsController {
    private readonly organizationsService;
    private readonly membershipsService;
    constructor(organizationsService: OrganizationsService, membershipsService: MembershipsService);
    create(req: any, dto: CreateOrganizationDto): Promise<{
        name: string;
        id: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
    }>;
    findAll(req: any): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        role: import("@prisma/client").$Enums.MembershipRole;
    }[]>;
    findOne(organizationId: string): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
    }>;
    update(organizationId: string, dto: UpdateOrganizationDto): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
    }>;
    getMembers(organizationId: string): Promise<{
        userId: string;
        email: string | null;
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
    transferOwnership(organizationId: string, req: any, dto: TransferOwnershipDto): Promise<{
        message: string;
    }>;
    leaveOrganization(organizationId: string, req: any): Promise<{
        message: string;
    }>;
}
