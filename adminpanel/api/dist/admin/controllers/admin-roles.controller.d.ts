import { AdminRolesService } from '../services/admin-roles.service.js';
import { AdminRoleQueryDto, AdminCreateRoleDto, AdminUpdateRoleDto } from '../dto/admin-roles.dto.js';
export declare class AdminRolesController {
    private readonly adminRolesService;
    constructor(adminRolesService: AdminRolesService);
    findAll(user: any, query: AdminRoleQueryDto): Promise<{
        data: ({
            _count: {
                permissions: number;
                memberships: number;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            name: import("@prisma/client").$Enums.AdminRole;
            isActive: boolean;
            description: string | null;
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(user: any, id: string): Promise<{
        permissions: {
            id: string;
            createdAt: Date;
            roleId: string;
            action: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: import("@prisma/client").$Enums.AdminRole;
        isActive: boolean;
        description: string | null;
    }>;
    createRole(user: any, dto: AdminCreateRoleDto): Promise<{
        permissions: {
            id: string;
            createdAt: Date;
            roleId: string;
            action: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: import("@prisma/client").$Enums.AdminRole;
        isActive: boolean;
        description: string | null;
    }>;
    updateRole(user: any, id: string, dto: AdminUpdateRoleDto): Promise<{
        permissions: {
            id: string;
            createdAt: Date;
            roleId: string;
            action: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: import("@prisma/client").$Enums.AdminRole;
        isActive: boolean;
        description: string | null;
    }>;
    grantSuperAdmin(user: any, targetUserId: string): Promise<{
        message: string;
    }>;
    revokeSuperAdmin(user: any, targetUserId: string): Promise<{
        message: string;
    }>;
}
