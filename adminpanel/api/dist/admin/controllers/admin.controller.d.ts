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
            id: string;
            createdAt: Date;
            updatedAt: Date;
            name: import("@prisma/client").$Enums.AdminRole;
            isActive: boolean;
            description: string | null;
        })[];
    }>;
}
