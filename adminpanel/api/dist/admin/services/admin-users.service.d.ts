import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminUserQueryDto, AdminUpdateUserDto } from '../dto/admin-users.dto.js';
export declare class AdminUsersService {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    findAll(query: AdminUserQueryDto): Promise<{
        data: {
            email: string;
            firstName: string | null;
            lastName: string | null;
            id: string;
            status: import("@prisma/client").$Enums.UserStatus;
            createdAt: Date;
        }[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(id: string): Promise<{
        email: string;
        firstName: string | null;
        lastName: string | null;
        id: string;
        status: import("@prisma/client").$Enums.UserStatus;
        lastLoginAt: Date | null;
        createdAt: Date;
    }>;
    updateUser(actorId: string, id: string, dto: AdminUpdateUserDto): Promise<{
        email: string;
        firstName: string | null;
        lastName: string | null;
        id: string;
        status: import("@prisma/client").$Enums.UserStatus;
        createdAt: Date;
    }>;
}
