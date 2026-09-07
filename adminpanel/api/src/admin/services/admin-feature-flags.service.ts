import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminFeatureFlagQueryDto, AdminCreateFeatureFlagDto, AdminUpdateFeatureFlagDto } from '../dto/admin-feature-flags.dto.js';

@Injectable()
export class AdminFeatureFlagsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async findAll(actorId: string, query: AdminFeatureFlagQueryDto) {
    const { page, limit, search, isActive, skip } = query;

    const where: any = {};
    if (isActive !== undefined) where.isActive = isActive;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { key: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.featureFlag.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.featureFlag.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }

  async findOne(actorId: string, flagId: string) {
    const flag = await this.prisma.featureFlag.findUnique({
      where: { id: flagId },
    });

    if (!flag) throw new NotFoundException('Feature flag not found');
    return flag;
  }

  async createFeatureFlag(actorId: string, dto: AdminCreateFeatureFlagDto) {
    const existing = await this.prisma.featureFlag.findUnique({ where: { key: dto.key } });
    if (existing) throw new ConflictException('Feature flag with this key already exists');

    return this.prisma.$transaction(async (tx) => {
      const flag = await tx.featureFlag.create({
        data: dto,
      });

      await this.auditService.log(actorId, 'FEATURE_FLAG_CREATED', 'FeatureFlag', flag.id, null, null, flag, tx);
      return flag;
    });
  }

  async updateFeatureFlag(actorId: string, flagId: string, dto: AdminUpdateFeatureFlagDto) {
    const flag = await this.prisma.featureFlag.findUnique({ where: { id: flagId } });
    if (!flag) throw new NotFoundException('Feature flag not found');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.featureFlag.update({
        where: { id: flagId },
        data: dto,
      });

      await this.auditService.log(actorId, 'FEATURE_FLAG_UPDATED', 'FeatureFlag', flag.id, null, flag, updated, tx);
      return updated;
    });
  }
}
