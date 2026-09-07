var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
let AdminPlansService = class AdminPlansService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async findAll(actorId, query) {
        const { page, limit, search, status, skip } = query;
        const where = {};
        if (status !== undefined)
            where.status = status;
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
    async findOne(actorId, planId) {
        const plan = await this.prisma.plan.findUnique({
            where: { id: planId },
            include: { features: true, limits: true },
        });
        if (!plan)
            throw new NotFoundException('Plan not found');
        return plan;
    }
    async createPlan(actorId, dto) {
        const existing = await this.prisma.plan.findUnique({ where: { slug: dto.slug } });
        if (existing)
            throw new ConflictException('Plan with this slug already exists');
        return this.prisma.$transaction(async (tx) => {
            const plan = await tx.plan.create({
                data: {
                    name: dto.name,
                    slug: dto.slug,
                    description: dto.description,
                    monthlyPrice: dto.monthlyPrice,
                    yearlyPrice: dto.yearlyPrice,
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
    async updatePlan(actorId, planId, dto) {
        const plan = await this.prisma.plan.findUnique({ where: { id: planId } });
        if (!plan)
            throw new NotFoundException('Plan not found');
        return this.prisma.$transaction(async (tx) => {
            const updateData = {};
            if (dto.name !== undefined)
                updateData.name = dto.name;
            if (dto.description !== undefined)
                updateData.description = dto.description;
            if (dto.monthlyPrice !== undefined)
                updateData.monthlyPrice = dto.monthlyPrice;
            if (dto.yearlyPrice !== undefined)
                updateData.yearlyPrice = dto.yearlyPrice;
            if (dto.currency !== undefined)
                updateData.currency = dto.currency;
            if (dto.status !== undefined)
                updateData.status = dto.status;
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
};
AdminPlansService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminPlansService);
export { AdminPlansService };
//# sourceMappingURL=admin-plans.service.js.map