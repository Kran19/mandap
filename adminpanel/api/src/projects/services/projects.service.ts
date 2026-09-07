import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { EntitlementService } from '../../billing/services/entitlement.service.js';
import { Prisma, ProjectStatus } from '@prisma/client';

export class CreateProjectDto {
  name: string;
  description?: string;
  organizationId: string;
}

export class UpdateProjectDto {
  name?: string;
  description?: string;
}

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly entitlementService: EntitlementService,
  ) {}

  async create(actorId: string, orgId: string, dto: CreateProjectDto) {
    if (orgId !== dto.organizationId) {
      throw new ForbiddenException('Organization ID mismatch');
    }

    return this.prisma.$transaction(async (tx) => {
      // Enforce max_projects limit
      const maxProjects = await this.entitlementService.getLimit(orgId, 'max_projects');
      if (maxProjects !== null) {
        // Count active and archived projects
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

      // Create Project
      const project = await tx.project.create({
        data: {
          name: dto.name,
          description: dto.description,
          organizationId: orgId,
          createdBy: actorId,
          status: ProjectStatus.ACTIVE,
        },
      });

      // Maintain UsageMetric (idempotent upsert since it's an aggregate count)
      const count = await tx.project.count({
        where: {
          organizationId: orgId,
          status: { in: [ProjectStatus.ACTIVE, ProjectStatus.ARCHIVED] },
        },
      });
      await this.upsertProjectsUsage(tx, orgId, count);

      // Audit Log
      await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_CREATED', 'Project', project.id, null, project);

      return project;
    });
  }

  async findAll(orgId: string, page: number = 1, limit: number = 25) {
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

  async findOne(orgId: string, projectId: string) {
    const project = await this.prisma.project.findFirst({
      where: { id: projectId, organizationId: orgId },
    });
    if (!project) throw new NotFoundException('Project not found');
    return project;
  }

  async update(actorId: string, orgId: string, projectId: string, dto: UpdateProjectDto) {
    return this.prisma.$transaction(async (tx) => {
      const project = await tx.project.findFirst({
        where: { id: projectId, organizationId: orgId },
      });
      if (!project) throw new NotFoundException('Project not found');
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

  async archive(actorId: string, orgId: string, projectId: string) {
    return this.prisma.$transaction(async (tx) => {
      const project = await tx.project.findFirst({
        where: { id: projectId, organizationId: orgId },
      });
      if (!project) throw new NotFoundException('Project not found');
      if (project.status === ProjectStatus.ARCHIVED) return project;

      const updated = await tx.project.update({
        where: { id: projectId },
        data: {
          status: ProjectStatus.ARCHIVED,
          archivedAt: new Date(),
        },
      });

      // Count does not change since archived projects still count towards limits
      await this.logCustomerAudit(tx, actorId, orgId, 'PROJECT_ARCHIVED', 'Project', project.id, project, updated);

      return updated;
    });
  }

  async restore(actorId: string, orgId: string, projectId: string) {
    return this.prisma.$transaction(async (tx) => {
      const project = await tx.project.findFirst({
        where: { id: projectId, organizationId: orgId },
      });
      if (!project) throw new NotFoundException('Project not found');
      if (project.status === ProjectStatus.ACTIVE) return project;

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

  async remove(actorId: string, orgId: string, projectId: string) {
    return this.prisma.$transaction(async (tx) => {
      const project = await tx.project.findFirst({
        where: { id: projectId, organizationId: orgId },
      });
      if (!project) throw new NotFoundException('Project not found');

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

  private async upsertProjectsUsage(tx: Prisma.TransactionClient, organizationId: string, count: number) {
    const existing = await tx.usageMetric.findFirst({
      where: { organizationId, metric: 'projects' },
    });
    if (existing) {
      await tx.usageMetric.update({
        where: { id: existing.id },
        data: { value: count },
      });
    } else {
      await tx.usageMetric.create({
        data: {
          organizationId,
          metric: 'projects',
          value: count,
        },
      });
    }
  }

  async logCustomerAudit(
    tx: Prisma.TransactionClient,
    actorUserId: string,
    organizationId: string,
    action: string,
    resourceType: string,
    resourceId?: string,
    before?: any,
    after?: any,
  ) {
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
}
