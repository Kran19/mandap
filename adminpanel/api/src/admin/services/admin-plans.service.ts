import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminPlanQueryDto, AdminCreatePlanDto, AdminUpdatePlanDto } from '../dto/admin-plans.dto.js';

@Injectable()
export class AdminPlansService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async findAll(actorId: string, query: AdminPlanQueryDto) {
    const { page, limit, search, status, skip } = query;

    const where: any = {};
    if (status !== undefined) where.status = status;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { slug: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.plan.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: { features: true, limits: true },
      }),
      this.prisma.plan.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }

  async findOne(actorId: string, planId: string) {
    const plan = await this.prisma.plan.findUnique({
      where: { id: planId },
      include: { features: true, limits: true },
    });

    if (!plan) throw new NotFoundException('Plan not found');
    return plan;
  }

  async createPlan(actorId: string, dto: AdminCreatePlanDto) {
    const existing = await this.prisma.plan.findUnique({ where: { slug: dto.slug } });
    if (existing) throw new ConflictException('Plan with this slug already exists');

    return this.prisma.$transaction(async (tx) => {
      const plan = await tx.plan.create({
        data: {
          name: dto.name,
          slug: dto.slug,
          description: dto.description,
          monthlyPrice: dto.monthlyPrice as any,
          yearlyPrice: dto.yearlyPrice as any,
          currency: dto.currency || 'USD',
          status: dto.status || 'ACTIVE',
          features: dto.features ? {
            create: dto.features,
          } : undefined,
          limits: dto.limits ? {
            create: dto.limits.map(l => ({ key: l.key, value: l.limit })),
          } : undefined,
        },
        include: { features: true, limits: true },
      });

      await this.auditService.log(actorId, 'PLAN_CREATED', 'Plan', plan.id, null, null, plan, tx);
      return plan;
    });
  }

  async updatePlan(actorId: string, planId: string, dto: AdminUpdatePlanDto) {
    const plan = await this.prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) throw new NotFoundException('Plan not found');

    return this.prisma.$transaction(async (tx) => {
      const updateData: any = {};
      if (dto.name !== undefined) updateData.name = dto.name;
      if (dto.description !== undefined) updateData.description = dto.description;
      if (dto.monthlyPrice !== undefined) updateData.monthlyPrice = dto.monthlyPrice as any;
      if (dto.yearlyPrice !== undefined) updateData.yearlyPrice = dto.yearlyPrice as any;
      if (dto.currency !== undefined) updateData.currency = dto.currency;
      if (dto.status !== undefined) updateData.status = dto.status;

      if (dto.features) {
        await tx.planFeature.deleteMany({ where: { planId } });
        updateData.features = { create: dto.features };
      }

      if (dto.limits) {
        await tx.planLimit.deleteMany({ where: { planId } });
        updateData.limits = { create: dto.limits.map(l => ({ key: l.key, value: l.limit })) };
      }

      const updated = await tx.plan.update({
        where: { id: planId },
        data: updateData,
        include: { features: true, limits: true },
      });

      await this.auditService.log(actorId, 'PLAN_UPDATED', 'Plan', plan.id, null, plan, updated, tx);
      return updated;
    });
  }
}
