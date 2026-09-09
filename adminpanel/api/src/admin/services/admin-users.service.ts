import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminUserQueryDto, AdminUpdateUserDto } from '../dto/admin-users.dto.js';
import { UserStatus } from '@prisma/client';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async findAll(query: AdminUserQueryDto) {
    const { page, limit, status, search, skip } = query;

    const where: any = {};
    if (status) where.status = status;
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          status: true,
          createdAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        status: true,
        createdAt: true,
        lastLoginAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async updateUser(actorId: string, id: string, dto: AdminUpdateUserDto) {
    const user = await this.findOne(id);
    const { status } = dto;

    if (!status || status === user.status) {
      return user;
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedUser = await tx.user.update({
        where: { id },
        data: { status },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          status: true,
          createdAt: true,
        },
      });

      // If deactivated, revoke all active refresh sessions
      if (status !== UserStatus.ACTIVE) {
        await tx.refreshSession.updateMany({
          where: { userId: id, revokedAt: null },
          data: { revokedAt: new Date() },
        });
      }

      await this.auditService.log(
        actorId,
        'USER_STATUS_CHANGED',
        'User',
        id,
        null,
        { status: user.status },
        { status },
        tx,
      );

      return updatedUser;
    });
  }

  async deleteUser(actorId: string, id: string) {
    if (actorId === id) {
      throw new BadRequestException('You cannot delete your own admin account.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Delete dependent trial setups and claims if any
      await tx.trialClaim.deleteMany({ where: { userId: id } });
      await tx.trialSetup.deleteMany({ where: { userId: id } });

      // 2. Clear user reference from orders so orders remain for accounting/history
      await tx.order.updateMany({
        where: { userId: id },
        data: { userId: null },
      });

      // 3. Clear refresh sessions
      await tx.refreshSession.deleteMany({ where: { userId: id } });

      // 4. Delete user (OrganizationMember and AdminMembership cascade automatically)
      const deletedUser = await tx.user.delete({
        where: { id },
      });

      // 5. Log audit entry
      await this.auditService.log(
        actorId,
        'USER_DELETED',
        'User',
        id,
        {
          deletedEmail: user.email,
          deletedName: `${user.firstName || ''} ${user.lastName || ''}`.trim(),
        },
        {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          status: user.status,
        },
        null,
        tx,
      );

      return { success: true, id: deletedUser.id };
    });
  }
}
