import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminUsageQueryDto } from '../dto/admin-usage.dto.js';

@Injectable()
export class AdminUsageService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(actorId: string, query: AdminUsageQueryDto) {
    const { page, limit, organizationId, metricName, skip } = query;

    const where: any = {};
    if (organizationId) where.organizationId = organizationId;
    if (metricName) where.metricName = metricName;

    const [data, total] = await Promise.all([
      this.prisma.usageMetric.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.usageMetric.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }
}
