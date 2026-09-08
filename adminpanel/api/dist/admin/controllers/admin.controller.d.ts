import { PrismaService } from '../../prisma.service.js';
export declare class AdminController {
    private prisma;
    constructor(prisma: PrismaService);
    getMe(user: any): Promise<{
        id: any;
        email: any;
        firstName: any;
        lastName: any;
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
}
