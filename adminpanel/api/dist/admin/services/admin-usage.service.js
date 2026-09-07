var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
let AdminUsageService = class AdminUsageService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(actorId, query) {
        const { page, limit, organizationId, metricName, skip } = query;
        const where = {};
        if (organizationId)
            where.organizationId = organizationId;
        if (metricName)
            where.metricName = metricName;
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
};
AdminUsageService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], AdminUsageService);
export { AdminUsageService };
//# sourceMappingURL=admin-usage.service.js.map