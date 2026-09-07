import { PrismaService } from '../../prisma.service.js';
import { Prisma } from '@prisma/client';
export declare class AdminAuditService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    log(actorId: string, action: string, resourceType: string, resourceId?: string, metadata?: any, before?: any, after?: any, tx?: Prisma.TransactionClient): Promise<void>;
}
