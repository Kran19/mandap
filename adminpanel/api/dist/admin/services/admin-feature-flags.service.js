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
let AdminFeatureFlagsService = class AdminFeatureFlagsService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async findAll(actorId, query) {
        const { page, limit, search, isActive, skip } = query;
        const where = {};
        if (isActive !== undefined)
            where.isActive = isActive;
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
    async findOne(actorId, flagId) {
        const flag = await this.prisma.featureFlag.findUnique({
            where: { id: flagId },
        });
        if (!flag)
            throw new NotFoundException('Feature flag not found');
        return flag;
    }
    async createFeatureFlag(actorId, dto) {
        const existing = await this.prisma.featureFlag.findUnique({ where: { key: dto.key } });
        if (existing)
            throw new ConflictException('Feature flag with this key already exists');
        return this.prisma.$transaction(async (tx) => {
            const flag = await tx.featureFlag.create({
                data: dto,
            });
            await this.auditService.log(actorId, 'FEATURE_FLAG_CREATED', 'FeatureFlag', flag.id, null, null, flag, tx);
            return flag;
        });
    }
    async updateFeatureFlag(actorId, flagId, dto) {
        const flag = await this.prisma.featureFlag.findUnique({ where: { id: flagId } });
        if (!flag)
            throw new NotFoundException('Feature flag not found');
        return this.prisma.$transaction(async (tx) => {
            const updated = await tx.featureFlag.update({
                where: { id: flagId },
                data: dto,
            });
            await this.auditService.log(actorId, 'FEATURE_FLAG_UPDATED', 'FeatureFlag', flag.id, null, flag, updated, tx);
            return updated;
        });
    }
};
AdminFeatureFlagsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminFeatureFlagsService);
export { AdminFeatureFlagsService };
//# sourceMappingURL=admin-feature-flags.service.js.map