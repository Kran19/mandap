import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminRoleQueryDto, AdminCreateRoleDto, AdminUpdateRoleDto } from '../dto/admin-roles.dto.js';
export declare class AdminRolesService {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    grantSuperAdmin(actorUserId: string, targetUserId: string): Promise<{
        message: string;
    }>;
    revokeSuperAdmin(actorUserId: string, targetUserId: string): Promise<{
        message: string;
    }>;
    private requireSuperAdmin;
    findAll(actorUserId: string, query: AdminRoleQueryDto): Promise<{
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
    findOne(actorUserId: string, roleId: string): Promise<{
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
    createRole(actorUserId: string, dto: AdminCreateRoleDto): Promise<{
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
    updateRole(actorUserId: string, roleId: string, dto: AdminUpdateRoleDto): Promise<{
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
}
