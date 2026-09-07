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
let AdminProjectsService = class AdminProjectsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(actorId, query) {
        const { page, limit, search, status, organizationId, skip } = query;
        const where = {};
        if (status)
            where.status = status;
        if (organizationId)
            where.organizationId = organizationId;
        if (search) {
            where.name = { contains: search, mode: 'insensitive' };
        }
        const [data, total] = await Promise.all([
            this.prisma.project.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    organization: { select: { id: true, name: true, slug: true } },
                    _count: { select: { versions: true } },
                },
            }),
            this.prisma.project.count({ where }),
        ]);
        return {
            data,
            meta: { total, page, limit },
        };
    }
    async findOne(actorId, projectId) {
        const project = await this.prisma.project.findUnique({
            where: { id: projectId },
            include: {
                organization: { select: { id: true, name: true, slug: true } },
                versions: {
                    orderBy: { versionNumber: 'desc' },
                    take: 10,
                },
                _count: { select: { versions: true } },
            },
        });
        if (!project)
            throw new NotFoundException('Project not found');
        return project;
    }
    async findVersion(actorId, projectId, versionId) {
        const version = await this.prisma.projectVersion.findUnique({
            where: { id: versionId, projectId },
        });
        if (!version)
            throw new NotFoundException('Version not found');
        return version;
    }
};
AdminProjectsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], AdminProjectsService);
export { AdminProjectsService };
//# sourceMappingURL=admin-projects.service.js.map