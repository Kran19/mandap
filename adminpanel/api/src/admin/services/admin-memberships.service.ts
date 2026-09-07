import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminMembershipQueryDto, AdminAddMembershipDto, AdminUpdateMembershipDto } from '../dto/admin-memberships.dto.js';
import { MembershipRole } from '@prisma/client';

@Injectable()
export class AdminMembershipsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async findAll(actorId: string, orgId: string, query: AdminMembershipQueryDto) {
    const { page, limit, role, userId, skip } = query;

    const where: any = { organizationId: orgId };
    if (role) where.role = role;
    if (userId) where.userId = userId;

    const [data, total] = await Promise.all([
      this.prisma.organizationMember.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, email: true, status: true } },
        },
      }),
      this.prisma.organizationMember.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }

  async addMember(actorId: string, orgId: string, dto: AdminAddMembershipDto) {
    if (dto.role === MembershipRole.OWNER) {
      throw new BadRequestException('Cannot assign OWNER role via generic membership API.');
    }

    const org = await this.prisma.organization.findUnique({ where: { id: orgId } });
    if (!org) throw new NotFoundException('Organization not found');

    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new NotFoundException('User not found');

    const existing = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: orgId, userId: dto.userId } },
    });
    if (existing) {
      throw new ConflictException('User is already a member of this organization.');
    }

    return this.prisma.$transaction(async (tx) => {
      const membership = await tx.organizationMember.create({
        data: {
          organizationId: orgId,
          userId: dto.userId,
          role: dto.role,
        },
      });

      await this.auditService.log(
        actorId,
        'MEMBERSHIP_ADDED',
        'OrganizationMember',
        membership.id,
        { organizationId: orgId, role: dto.role },
        null,
        membership,
        tx,
      );

      return membership;
    });
  }

  async updateMemberRole(actorId: string, orgId: string, userId: string, dto: AdminUpdateMembershipDto) {
    if (dto.role === MembershipRole.OWNER) {
      throw new BadRequestException('Cannot assign OWNER role via generic membership API.');
    }

    return this.prisma.$transaction(async (tx) => {
      const membership = await tx.organizationMember.findUnique({
        where: { organizationId_userId: { organizationId: orgId, userId } },
      });

      if (!membership) {
        throw new NotFoundException('Membership not found.');
      }

      if (membership.role === MembershipRole.OWNER) {
        throw new BadRequestException('Cannot demote an OWNER. Ownership transfer is a dedicated operation.');
      }

      const updated = await tx.organizationMember.update({
        where: { id: membership.id },
        data: { role: dto.role },
      });

      await this.auditService.log(
        actorId,
        'MEMBERSHIP_ROLE_CHANGED',
        'OrganizationMember',
        membership.id,
        { organizationId: orgId },
        { role: membership.role },
        { role: updated.role },
        tx,
      );

      return updated;
    });
  }

  async removeMember(actorId: string, orgId: string, userId: string) {
    return this.prisma.$transaction(async (tx) => {
      const membership = await tx.organizationMember.findUnique({
        where: { organizationId_userId: { organizationId: orgId, userId } },
      });

      if (!membership) {
        throw new NotFoundException('Membership not found.');
      }

      if (membership.role === MembershipRole.OWNER) {
        throw new BadRequestException('Cannot remove an OWNER. Ownership transfer is a dedicated operation.');
      }

      await tx.organizationMember.delete({
        where: { id: membership.id },
      });

      await this.auditService.log(
        actorId,
        'MEMBERSHIP_REMOVED',
        'OrganizationMember',
        membership.id,
        { organizationId: orgId },
        membership,
        null,
        tx,
      );

      return { success: true };
    });
  }
}
