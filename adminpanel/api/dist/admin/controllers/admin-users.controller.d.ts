import { AdminUsersService } from '../services/admin-users.service.js';
import { AdminUserQueryDto, AdminUpdateUserDto } from '../dto/admin-users.dto.js';
export declare class AdminUsersController {
    private readonly usersService;
    constructor(usersService: AdminUsersService);
    findAll(query: AdminUserQueryDto): Promise<{
        data: {
            email: string | null;
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
        email: string | null;
        firstName: string | null;
        lastName: string | null;
        id: string;
        status: import("@prisma/client").$Enums.UserStatus;
        lastLoginAt: Date | null;
        createdAt: Date;
    }>;
    updateUser(actor: any, id: string, dto: AdminUpdateUserDto): Promise<{
        email: string | null;
        firstName: string | null;
        lastName: string | null;
        id: string;
        status: import("@prisma/client").$Enums.UserStatus;
        createdAt: Date;
    }>;
    deleteUser(actor: any, id: string): Promise<{
        success: boolean;
        id: string;
    }>;
}
