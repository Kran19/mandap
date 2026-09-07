var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminAuditService } from './admin-audit.service.js';
let AdminOrganizationsService = class AdminOrganizationsService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async getOrganization(actorUserId, organizationId) {
        const adminMembership = await this.prisma.adminMembership.findUnique({
            where: { userId: actorUserId },
            include: {
                role: { include: { permissions: true } },
            },
        });
        if (!adminMembership?.isActive || !adminMembership.role?.isActive) {
            throw new ForbiddenException('Actor is not an active administrator.');
        }
        const hasPermission = adminMembership.role.permissions.some((p) => p.action === AdminPermissions.ORGANIZATIONS_READ);
        if (!hasPermission) {
            throw new ForbiddenException('Actor lacks explicit administrative permission to read organizations.');
        }
        const org = await this.prisma.organization.findUnique({
            where: { id: organizationId },
            include: {
                _count: {
                    select: { members: true, projects: true }
                }
            }
        });
        if (!org) {
            throw new NotFoundException('Organization not found.');
        }
        return {
            id: org.id,
            name: org.name,
            slug: org.slug,
            status: org.status,
            memberCount: org._count.members,
            projectCount: org._count.projects,
            createdAt: org.createdAt,
        };
    }
    async findAll(actorUserId, query) {
        const { page, limit, status, search, slug, skip } = query;
        const where = {};
        if (status)
            where.status = status;
        if (slug)
            where.slug = slug;
        if (search) {
            where.OR = [
                { name: { contains: search, mode: 'insensitive' } },
                { slug: { contains: search, mode: 'insensitive' } },
            ];
        }
        const [data, total] = await Promise.all([
            this.prisma.organization.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                select: {
                    id: true,
                    name: true,
                    slug: true,
                    status: true,
                    createdAt: true,
                },
            }),
            this.prisma.organization.count({ where }),
        ]);
        return {
            data,
            meta: { total, page, limit },
        };
    }
    async updateOrganization(actorUserId, organizationId, dto) {
        if (Object.keys(dto).length === 0) {
            throw new BadRequestException('No update data provided');
        }
        const org = await this.prisma.organization.findUnique({
            where: { id: organizationId },
        });
        if (!org) {
            throw new NotFoundException('Organization not found.');
        }
        return this.prisma.$transaction(async (tx) => {
            const updatedOrg = await tx.organization.update({
                where: { id: organizationId },
                data: dto,
                select: {
                    id: true,
                    name: true,
                    slug: true,
                    status: true,
                    createdAt: true,
                },
            });
            await this.auditService.log(actorUserId, 'ORGANIZATION_UPDATED', 'Organization', organizationId, null, { status: org.status, name: org.name }, dto, tx);
            return updatedOrg;
        });
    }
};
AdminOrganizationsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminOrganizationsService);
export { AdminOrganizationsService };
//# sourceMappingURL=admin-organizations.service.js.map