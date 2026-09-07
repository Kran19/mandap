import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { Prisma, ProjectStatus } from '@prisma/client';
import { CreateProjectVersionDto, LayoutDataEnvelope } from '../validators/layout.validator.js';
import * as crypto from 'crypto';

@Injectable()
export class ProjectVersionsService {
  constructor(private readonly prisma: PrismaService) {}

  async createVersion(
    actorId: string,
    orgId: string,
    projectId: string,
    dto: CreateProjectVersionDto,
    idempotencyKey?: string,
  ) {
    return this.prisma.$transaction(
      async (tx) => {
        // 0. Idempotency Check
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

        // 1. Verify project exists and belongs to org
        const project = await tx.project.findFirst({
          where: { id: projectId, organizationId: orgId },
        });

        if (!project) throw new NotFoundException('Project not found');
        if (project.status === ProjectStatus.ARCHIVED) {
          throw new ForbiddenException('Cannot create a version for an archived project');
        }

        // 2. Concurrency check (optimistic locking)
        if (dto.expectedCurrentVersionId && project.currentVersionId !== dto.expectedCurrentVersionId) {
          throw new ConflictException(
            `Expected current version was ${dto.expectedCurrentVersionId}, but project is actually at ${project.currentVersionId}. Please fetch the latest layout before saving.`,
          );
        } else if (!dto.expectedCurrentVersionId && project.currentVersionId) {
            throw new ConflictException(
                `Project already has versions. You must provide expectedCurrentVersionId.`,
              );
        }

        // 3. Determine next version number
        const agg = await tx.projectVersion.aggregate({
          where: { projectId },
          _max: { versionNumber: true },
        });
        const nextVersionNumber = (agg._max.versionNumber || 0) + 1;

        // 4. Create version
        const newVersion = await tx.projectVersion.create({
          data: {
            projectId,
            versionNumber: nextVersionNumber,
            layoutData: dto.layoutData as any,
            createdBy: actorId,
          },
        });

        // 5. Update Project currentVersionId
        await tx.project.update({
          where: { id: projectId },
          data: { currentVersionId: newVersion.id },
        });

        // 6. Audit Log
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

        // 7. Store Idempotency Record
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
              responseBody: newVersion as any,
              expiresAt,
            }
          });
        }

        return newVersion;
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
      },
    );
  }

  async restoreVersion(actorId: string, orgId: string, projectId: string, versionIdToRestore: string) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Verify project
      const project = await tx.project.findFirst({
        where: { id: projectId, organizationId: orgId },
      });
      if (!project) throw new NotFoundException('Project not found');
      if (project.status === ProjectStatus.ARCHIVED) {
        throw new ForbiddenException('Cannot restore a version for an archived project');
      }

      // 2. Load the old version
      const oldVersion = await tx.projectVersion.findFirst({
        where: { id: versionIdToRestore, projectId },
      });
      if (!oldVersion) throw new NotFoundException('Version not found');

      // 3. Determine next version number
      const agg = await tx.projectVersion.aggregate({
        where: { projectId },
        _max: { versionNumber: true },
      });
      const nextVersionNumber = (agg._max.versionNumber || 0) + 1;

      // 4. Create new version with old layoutData
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

      // 5. Update Project currentVersionId
      await tx.project.update({
        where: { id: projectId },
        data: { currentVersionId: restoredVersion.id },
      });

      // 6. Audit Log
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

  async findHistory(orgId: string, projectId: string, page: number = 1, limit: number = 25) {
    // 1. Verify project visibility
    const project = await this.prisma.project.findFirst({
      where: { id: projectId, organizationId: orgId },
    });
    if (!project) throw new NotFoundException('Project not found');

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.projectVersion.findMany({
        where: { projectId },
        skip,
        take: limit,
        orderBy: { versionNumber: 'desc' },
        // omit layoutData in history listing if it's large, but Prisma currently requires select/exclude
        // For phase 8, we can select explicitly to avoid fetching massive layout JSONs in the list
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

  async findOne(orgId: string, projectId: string, versionId: string) {
    const project = await this.prisma.project.findFirst({
      where: { id: projectId, organizationId: orgId },
    });
    if (!project) throw new NotFoundException('Project not found');

    const version = await this.prisma.projectVersion.findFirst({
      where: { id: versionId, projectId },
    });
    if (!version) throw new NotFoundException('Version not found');

    return version;
  }
}
