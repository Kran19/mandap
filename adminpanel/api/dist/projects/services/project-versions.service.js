var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { Prisma, ProjectStatus } from '@prisma/client';
import * as crypto from 'crypto';
let ProjectVersionsService = class ProjectVersionsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createVersion(actorId, orgId, projectId, dto, idempotencyKey) {
        return this.prisma.$transaction(async (tx) => {
            let requestHash = '';
            if (idempotencyKey) {
                requestHash = crypto.createHash('sha256').update(JSON.stringify(dto)).digest('hex');
                const existingRecord = await tx.idempotencyRecord.findUnique({
                    where: {
                        organizationId_userId_endpoint_idempotencyKey: {
                            organizationId: orgId,
                            userId: actorId,
                            endpoint: 'POST_PROJECT_VERSIONS',
                            idempotencyKey: idempotencyKey,
                        }
                    }
                });
                if (existingRecord) {
                    if (existingRecord.requestHash !== requestHash) {
                        throw new ConflictException('Idempotency key reused with a different payload hash.');
                    }
                    if (existingRecord.status === 'COMPLETED' && existingRecord.responseBody) {
                        return existingRecord.responseBody;
                    }
                    throw new ConflictException('Idempotency key is currently processing. Please try again.');
                }
            }
            const project = await tx.project.findFirst({
                where: { id: projectId, organizationId: orgId },
            });
            if (!project)
                throw new NotFoundException('Project not found');
            if (project.status === ProjectStatus.ARCHIVED) {
                throw new ForbiddenException('Cannot create a version for an archived project');
            }
            if (dto.expectedCurrentVersionId && project.currentVersionId !== dto.expectedCurrentVersionId) {
                throw new ConflictException(`Expected current version was ${dto.expectedCurrentVersionId}, but project is actually at ${project.currentVersionId}. Please fetch the latest layout before saving.`);
            }
            else if (!dto.expectedCurrentVersionId && project.currentVersionId) {
                throw new ConflictException(`Project already has versions. You must provide expectedCurrentVersionId.`);
            }
            const agg = await tx.projectVersion.aggregate({
                where: { projectId },
                _max: { versionNumber: true },
            });
            const nextVersionNumber = (agg._max.versionNumber || 0) + 1;
            const newVersion = await tx.projectVersion.create({
                data: {
                    projectId,
                    versionNumber: nextVersionNumber,
                    layoutData: dto.layoutData,
                    createdBy: actorId,
                },
            });
            await tx.project.update({
                where: { id: projectId },
                data: { currentVersionId: newVersion.id },
            });
            await tx.auditLog.create({
                data: {
                    actorUserId: actorId,
                    organizationId: orgId,
                    action: 'PROJECT_VERSION_CREATED',
                    resourceType: 'ProjectVersion',
                    resourceId: newVersion.id,
                    metadata: {
                        projectId,
                        versionNumber: nextVersionNumber,
                    },
                },
            });
            if (idempotencyKey) {
                const expiresAt = new Date();
                expiresAt.setHours(expiresAt.getHours() + 24);
                await tx.idempotencyRecord.create({
                    data: {
                        organizationId: orgId,
                        userId: actorId,
                        endpoint: 'POST_PROJECT_VERSIONS',
                        idempotencyKey,
                        requestHash,
                        status: 'COMPLETED',
                        responseStatus: 201,
                        responseBody: newVersion,
                        expiresAt,
                    }
                });
            }
            return newVersion;
        }, {
            isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
        });
    }
    async restoreVersion(actorId, orgId, projectId, versionIdToRestore) {
        return this.prisma.$transaction(async (tx) => {
            const project = await tx.project.findFirst({
                where: { id: projectId, organizationId: orgId },
            });
            if (!project)
                throw new NotFoundException('Project not found');
            if (project.status === ProjectStatus.ARCHIVED) {
                throw new ForbiddenException('Cannot restore a version for an archived project');
            }
            const oldVersion = await tx.projectVersion.findFirst({
                where: { id: versionIdToRestore, projectId },
            });
            if (!oldVersion)
                throw new NotFoundException('Version not found');
            const agg = await tx.projectVersion.aggregate({
                where: { projectId },
                _max: { versionNumber: true },
            });
            const nextVersionNumber = (agg._max.versionNumber || 0) + 1;
            const restoredVersion = await tx.projectVersion.create({
                data: {
                    projectId,
                    versionNumber: nextVersionNumber,
                    layoutData: oldVersion.layoutData ?? Prisma.DbNull,
                    metadata: {
                        restoredFrom: oldVersion.id,
                        restoredFromVersionNumber: oldVersion.versionNumber,
                    },
                    createdBy: actorId,
                },
            });
            await tx.project.update({
                where: { id: projectId },
                data: { currentVersionId: restoredVersion.id },
            });
            await tx.auditLog.create({
                data: {
                    actorUserId: actorId,
                    organizationId: orgId,
                    action: 'PROJECT_VERSION_RESTORED',
                    resourceType: 'ProjectVersion',
                    resourceId: restoredVersion.id,
                    metadata: {
                        projectId,
                        versionNumber: nextVersionNumber,
                        restoredFrom: oldVersion.id,
                    },
                },
            });
            return restoredVersion;
        });
    }
    async findHistory(orgId, projectId, page = 1, limit = 25) {
        const project = await this.prisma.project.findFirst({
            where: { id: projectId, organizationId: orgId },
        });
        if (!project)
            throw new NotFoundException('Project not found');
        const skip = (page - 1) * limit;
        const [data, total] = await Promise.all([
            this.prisma.projectVersion.findMany({
                where: { projectId },
                skip,
                take: limit,
                orderBy: { versionNumber: 'desc' },
                select: {
                    id: true,
                    projectId: true,
                    versionNumber: true,
                    createdBy: true,
                    createdAt: true,
                    metadata: true,
                },
            }),
            this.prisma.projectVersion.count({ where: { projectId } }),
        ]);
        return { data, meta: { total, page, limit } };
    }
    async findOne(orgId, projectId, versionId) {
        const project = await this.prisma.project.findFirst({
            where: { id: projectId, organizationId: orgId },
        });
        if (!project)
            throw new NotFoundException('Project not found');
        const version = await this.prisma.projectVersion.findFirst({
            where: { id: versionId, projectId },
        });
        if (!version)
            throw new NotFoundException('Version not found');
        return version;
    }
};
ProjectVersionsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], ProjectVersionsService);
export { ProjectVersionsService };
//# sourceMappingURL=project-versions.service.js.map