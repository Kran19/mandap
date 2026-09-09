import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from '../services/admin-audit.service.js';
import { AdminUpdateProfileDto, AdminChangePasswordDto } from '../dto/admin-profile.dto.js';
export declare class AdminController {
    private prisma;
    private auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    getMe(user: any): Promise<{
        id: any;
        email: any;
        firstName: any;
        lastName: any;
        phone: any;
        status: any;
        roles: ({
            permissions: {
                id: string;
                createdAt: Date;
                roleId: string;
                action: string;
            }[];
        } & {
            name: import("@prisma/client").$Enums.AdminRole;
            id: string;
            createdAt: Date;
            updatedAt: Date;
            isActive: boolean;
            description: string | null;
        })[];
    }>;
    updateProfile(user: any, dto: AdminUpdateProfileDto): Promise<{
        email: string | null;
        firstName: string | null;
        lastName: string | null;
        phone: string | null;
        id: string;
        status: import("@prisma/client").$Enums.UserStatus;
    }>;
    changePassword(user: any, dto: AdminChangePasswordDto): Promise<{
        success: boolean;
        message: string;
    }>;
}
