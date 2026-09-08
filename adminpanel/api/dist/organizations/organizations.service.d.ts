import { PrismaService } from '../prisma.service.js';
import { CreateOrganizationDto } from './dto/create-organization.dto.js';
import { UpdateOrganizationDto } from './dto/update-organization.dto.js';
export declare class OrganizationsService {
    private prisma;
    constructor(prisma: PrismaService);
    createOrganization(userId: string, dto: CreateOrganizationDto): Promise<{
        name: string;
        id: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
    }>;
    getUserOrganizations(userId: string): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        role: import("@prisma/client").$Enums.MembershipRole;
    }[]>;
    getOrganization(organizationId: string): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
    }>;
    updateOrganization(organizationId: string, dto: UpdateOrganizationDto): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
    }>;
    private generateSlug;
}
