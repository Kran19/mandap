var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { EntitlementService } from '../../billing/services/entitlement.service.js';
import { ProjectStatus } from '@prisma/client';
export class CreateProjectDto {
    name;
    description;
    organizationId;
}
export class UpdateProjectDto {
    name;
    description;
}
let ProjectsService = class ProjectsService {
    prisma;
    entitlementService;
    constructor(prisma, entitlementService) {
        this.prisma = prisma;
        this.entitlementService = entitlementService;
    }
    async create(actorId, orgId, dto) {
        if (orgId !== dto.organizationId) {
            throw new ForbiddenException('Organization ID mismatch');
        }
        return this.prisma.$transaction(async (tx) => {
            const maxProjects = await this.entitlementService.getLimit(orgId, 'max_projects');
            if (maxProjects !== null) {
                const currentCount = await tx.project.count({
                    where: {
                        organizationId: orgId,
                        status: { in: [ProjectStatus.ACTIVE, ProjectStatus.ARCHIVED] },
                    },
                });
                if (currentCount >= maxProjects) {
                    throw new ForbiddenException('Project limit reached');
                }
            }
            const project = await tx.project.create({
                data: {
                    name: dto.name,
                    description: dto.description,
                    organizationId: orgId,
                    createdBy: actorId,
                    status: ProjectStatus.ACTIVE,
                },
            });
            const count = await tx.project.count({
                where: {
                    organizationId: orgId,
                    status: { in: [ProjectStatus.ACTIVE, ProjectStatus.ARCHIVED] },
                },
            });
            await this.upsertProjectsUsage(tx, orgId, count);
            await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_CREATED', 'Project', project.id, null, project);
            return project;
        });
    }
    async findAll(orgId, page = 1, limit = 25) {
        const skip = (page - 1) * limit;
        const [data, total] = await Promise.all([
            this.prisma.project.findMany({
                where: { organizationId: orgId },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            this.prisma.project.count({ where: { organizationId: orgId } }),
        ]);
        return { data, meta: { total, page, limit } };
    }
    async findOne(orgId, projectId) {
        const project = await this.prisma.project.findFirst({
            where: { id: projectId, organizationId: orgId },
        });
        if (!project)
            throw new NotFoundException('Project not found');
        return project;
    }
    async update(actorId, orgId, projectId, dto) {
        return this.prisma.$transaction(async (tx) => {
            const project = await tx.project.findFirst({
                where: { id: projectId, organizationId: orgId },
            });
            if (!project)
                throw new NotFoundException('Project not found');
            if (project.status === ProjectStatus.ARCHIVED) {
                throw new ForbiddenException('Cannot modify an archived project');
            }
            const updated = await tx.project.update({
                where: { id: projectId },
                data: {
                    name: dto.name,
                    description: dto.description,
                },
            });
            await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_UPDATED', 'Project', project.id, project, updated);
            return updated;
        });
    }
    async archive(actorId, orgId, projectId) {
        return this.prisma.$transaction(async (tx) => {
            const project = await tx.project.findFirst({
                where: { id: projectId, organizationId: orgId },
            });
            if (!project)
                throw new NotFoundException('Project not found');
            if (project.status === ProjectStatus.ARCHIVED)
                return project;
            const updated = await tx.project.update({
                where: { id: projectId },
                data: {
                    status: ProjectStatus.ARCHIVED,
                    archivedAt: new Date(),
                },
            });
            await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_ARCHIVED', 'Project', project.id, project, updated);
            return updated;
        });
    }
    async restore(actorId, orgId, projectId) {
        return this.prisma.$transaction(async (tx) => {
            const project = await tx.project.findFirst({
                where: { id: projectId, organizationId: orgId },
            });
            if (!project)
                throw new NotFoundException('Project not found');
            if (project.status === ProjectStatus.ACTIVE)
                return project;
            const updated = await tx.project.update({
                where: { id: projectId },
                data: {
                    status: ProjectStatus.ACTIVE,
                    archivedAt: null,
                },
            });
            await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_RESTORED', 'Project', project.id, project, updated);
            return updated;
        });
    }
    async remove(actorId, orgId, projectId) {
        return this.prisma.$transaction(async (tx) => {
            const project = await tx.project.findFirst({
                where: { id: projectId, organizationId: orgId },
            });
            if (!project)
                throw new NotFoundException('Project not found');
            await tx.project.delete({
                where: { id: projectId },
            });
            const count = await tx.project.count({
                where: {
                    organizationId: orgId,
                    status: { in: [ProjectStatus.ACTIVE, ProjectStatus.ARCHIVED] },
                },
            });
            await this.upsertProjectsUsage(tx, orgId, count);
            await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_DELETED', 'Project', project.id, project, null);
            return project;
        });
    }
    async upsertProjectsUsage(tx, organizationId, count) {
        const existing = await tx.usageMetric.findFirst({
            where: { organizationId, metric: 'projects' },
        });
        if (existing) {
            await tx.usageMetric.update({
                where: { id: existing.id },
                data: { value: count },
            });
        }
        else {
            await tx.usageMetric.create({
                data: {
                    organizationId,
                    metric: 'projects',
                    value: count,
                },
            });
        }
    }
    async logCustomerAudit(tx, actorUserId, organizationId, action, resourceType, resourceId, before, after) {
        await tx.auditLog.create({
            data: {
                actorUserId,
                organizationId,
                action,
                resourceType,
                resourceId,
                before: before ? JSON.parse(JSON.stringify(before)) : undefined,
                after: after ? JSON.parse(JSON.stringify(after)) : undefined,
            },
        });
    }
};
ProjectsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        EntitlementService])
], ProjectsService);
export { ProjectsService };
//# sourceMappingURL=projects.service.js.map