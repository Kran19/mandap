import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class AdminAuditService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Log an administrative action.
   * Can accept an explicit Prisma transaction client to ensure the log is committed atomically with the mutation.
   */
  async log(
    actorId: string,
    action: string,
    resourceType: string,
    resourceId?: string,
    metadata?: any,
    before?: any,
    after?: any,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx || this.prisma;
    await client.auditLog.create({
      data: {
        adminId: actorId,
        actorUserId: actorId,
        action,
        resourceType,
        resourceId,
        metadata: metadata ? JSON.parse(JSON.stringify(metadata)) : undefined,
        before: before ? JSON.parse(JSON.stringify(before)) : undefined,
        after: after ? JSON.parse(JSON.stringify(after)) : undefined,
      },
    });
  }
}
