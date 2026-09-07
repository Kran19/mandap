import { AdminOrganizationsService } from '../services/admin-organizations.service.js';
import { AdminOrganizationQueryDto, AdminUpdateOrganizationDto } from '../dto/admin-organizations.dto.js';
export declare class AdminOrganizationsController {
    private readonly adminOrganizationsService;
    constructor(adminOrganizationsService: AdminOrganizationsService);
    findAll(user: any, query: AdminOrganizationQueryDto): Promise<{
        data: {
            id: string;
            status: import("@prisma/client").$Enums.OrganizationStatus;
            createdAt: Date;
            name: string;
            slug: string;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    getOrganization(user: any, id: string): Promise<{
        id: string;
        name: string;
        slug: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        memberCount: number;
        projectCount: number;
        createdAt: Date;
    }>;
    updateOrganization(user: any, id: string, dto: AdminUpdateOrganizationDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.OrganizationStatus;
        createdAt: Date;
        name: string;
        slug: string;
    }>;
}
