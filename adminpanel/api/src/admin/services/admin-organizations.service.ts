import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminOrganizationQueryDto, AdminUpdateOrganizationDto } from '../dto/admin-organizations.dto.js';

@Injectable()
export class AdminOrganizationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  /**
   * Retrieves an organization from the system admin context.
   * Service explicitly requires actorId to verify privileged status, 
   * proving the administrative authorization boundary independently.
   */
  async getOrganization(actorUserId: string, organizationId: string) {
    // 1. Service-level check to ensure actor actually has the correct permission
    // Even if the controller guard is present, we double check here for defense in depth.
    const adminMembership = await this.prisma.adminMembership.findUnique({
      where: { userId: actorUserId },
      include: {
        role: { include: { permissions: true } },
      },
    });

    if (!adminMembership?.isActive || !adminMembership.role?.isActive) {
      throw new ForbiddenException('Actor is not an active administrator.');
    }

    const hasPermission = adminMembership.role.permissions.some(
      (p) => p.action === AdminPermissions.ORGANIZATIONS_READ
    );

    if (!hasPermission) {
      throw new ForbiddenException('Actor lacks explicit administrative permission to read organizations.');
    }

    // 2. Perform the domain operation
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

  async findAll(actorUserId: string, query: AdminOrganizationQueryDto) {
    const { page, limit, status, search, slug, skip } = query;

    const where: any = {};
    if (status) where.status = status;
    if (slug) where.slug = slug;
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

  async updateOrganization(actorUserId: string, organizationId: string, dto: AdminUpdateOrganizationDto) {
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

      await this.auditService.log(
        actorUserId,
        'ORGANIZATION_UPDATED',
        'Organization',
        organizationId,
        null,
        { status: org.status, name: org.name },
        dto,
        tx,
      );

      return updatedOrg;
    });
  }
}
