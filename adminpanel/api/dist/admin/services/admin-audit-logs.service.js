var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
let AdminAuditLogsService = class AdminAuditLogsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(query) {
        const { page, limit, actorUserId, action, resourceType, resourceId, skip } = query;
        const where = {};
        if (actorUserId)
            where.adminId = actorUserId;
        if (action)
            where.action = action;
        if (resourceType)
            where.resourceType = resourceType;
        if (resourceId)
            where.resourceId = resourceId;
        const [data, total] = await Promise.all([
            this.prisma.auditLog.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            this.prisma.auditLog.count({ where }),
        ]);
        return {
            data,
            meta: {
                total,
                page,
                limit,
            },
        };
    }
    async findOne(id) {
        const auditLog = await this.prisma.auditLog.findUnique({
            where: { id },
        });
        if (!auditLog) {
            throw new NotFoundException('Audit log not found');
        }
        return auditLog;
    }
};
AdminAuditLogsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], AdminAuditLogsService);
export { AdminAuditLogsService };
//# sourceMappingURL=admin-audit-logs.service.js.map