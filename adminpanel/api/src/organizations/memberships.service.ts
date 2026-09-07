import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto.js';
import { MembershipRole } from '@prisma/client';

@Injectable()
export class MembershipsService {
  constructor(private prisma: PrismaService) {}

  async getMembers(organizationId: string) {
    const members = await this.prisma.organizationMember.findMany({
      where: { organizationId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            status: true,
          },
        },
      },
    });
    return members.map((m) => ({
      userId: m.userId,
      email: m.user.email,
      firstName: m.user.firstName,
      lastName: m.user.lastName,
      status: m.user.status,
      role: m.role,
      createdAt: m.createdAt,
    }));
  }

  async addMember(organizationId: string, dto: AddMemberDto) {
    if (dto.role === MembershipRole.OWNER) {
      throw new BadRequestException('Cannot add a member as OWNER directly.');
    }

    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('User with that email does not exist.');
    }

    try {
      const membership = await this.prisma.organizationMember.create({
        data: {
          organizationId,
          userId: user.id,
          role: dto.role,
        },
      });
      return { message: 'Member added successfully', userId: membership.userId, role: membership.role };
    } catch (error: any) {
      if (error.code === 'P2002') {
        throw new ConflictException('User is already a member of this organization.');
      }
      throw error;
    }
  }

  async updateMemberRole(organizationId: string, targetUserId: string, dto: UpdateMemberRoleDto) {
    if (dto.role === MembershipRole.OWNER) {
      throw new BadRequestException('Cannot set role to OWNER through this endpoint. Use ownership-transfer instead.');
    }

    const targetMembership = await this.prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: {
          organizationId,
          userId: targetUserId,
        },
      },
    });

    if (!targetMembership) {
      throw new NotFoundException('Member not found in organization.');
    }

    if (targetMembership.role === MembershipRole.OWNER) {
      throw new BadRequestException('Cannot demote the current OWNER. Transfer ownership instead.');
    }

    await this.prisma.organizationMember.update({
      where: {
        organizationId_userId: {
          organizationId,
          userId: targetUserId,
        },
      },
      data: {
        role: dto.role,
      },
    });

    return { message: 'Role updated successfully' };
  }

  async removeMember(organizationId: string, targetUserId: string) {
    const targetMembership = await this.prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: {
          organizationId,
          userId: targetUserId,
        },
      },
    });

    if (!targetMembership) {
      throw new NotFoundException('Member not found in organization.');
    }

    if (targetMembership.role === MembershipRole.OWNER) {
      throw new BadRequestException('Cannot remove the current OWNER. Transfer ownership first.');
    }

    await this.prisma.organizationMember.delete({
      where: {
        organizationId_userId: {
          organizationId,
          userId: targetUserId,
        },
      },
    });

    return { message: 'Member removed successfully' };
  }

  async transferOwnership(organizationId: string, currentOwnerId: string, newOwnerId: string) {
    if (currentOwnerId === newOwnerId) {
      throw new BadRequestException('You are already the owner.');
    }

    await this.prisma.$transaction(async (tx) => {
      // 1. Lock the organization members to prevent concurrent ownership transfers
      // We will perform a dummy update or select FOR UPDATE if using raw query.
      // Prisma doesn't support SELECT FOR UPDATE directly in the API for unrelated models without raw queries.
      // So we will do a raw query to lock the current owner's membership.
      await tx.$queryRaw`SELECT id FROM "OrganizationMember" WHERE "organizationId" = ${organizationId} AND "userId" = ${currentOwnerId} FOR UPDATE`;
      await tx.$queryRaw`SELECT id FROM "OrganizationMember" WHERE "organizationId" = ${organizationId} AND "userId" = ${newOwnerId} FOR UPDATE`;

      const currentOwner = await tx.organizationMember.findUnique({
        where: { organizationId_userId: { organizationId, userId: currentOwnerId } },
      });

      const newOwner = await tx.organizationMember.findUnique({
        where: { organizationId_userId: { organizationId, userId: newOwnerId } },
      });

      if (!currentOwner || currentOwner.role !== MembershipRole.OWNER) {
        throw new BadRequestException('You are not the current owner of this organization.');
      }

      if (!newOwner) {
        throw new NotFoundException('The target user is not a member of this organization.');
      }

      // 2. Perform the swap
      await tx.organizationMember.update({
        where: { id: currentOwner.id },
        data: { role: MembershipRole.EDITOR },
      });

      await tx.organizationMember.update({
        where: { id: newOwner.id },
        data: { role: MembershipRole.OWNER },
      });
    });

    return { message: 'Ownership transferred successfully' };
  }

  async leaveOrganization(organizationId: string, userId: string) {
    const membership = await this.prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: {
          organizationId,
          userId,
        },
      },
    });

    if (!membership) {
      throw new NotFoundException('You are not a member of this organization.');
    }

    if (membership.role === MembershipRole.OWNER) {
      throw new BadRequestException('The sole owner cannot leave the organization. Transfer ownership first.');
    }

    await this.prisma.organizationMember.delete({
      where: {
        organizationId_userId: {
          organizationId,
          userId,
        },
      },
    });

    return { message: 'You have left the organization.' };
  }
}
