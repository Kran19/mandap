import { Injectable, NotFoundException } from '@nestjs/common';
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
}
