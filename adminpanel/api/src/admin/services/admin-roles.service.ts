import { Injectable, ForbiddenException, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminRole } from '@prisma/client';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminRoleQueryDto, AdminCreateRoleDto, AdminUpdateRoleDto } from '../dto/admin-roles.dto.js';

@Injectable()
export class AdminRolesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  /**
   * Promotes a user to SUPER_ADMIN.
   * Only an active SUPER_ADMIN may perform this.
   */
  async grantSuperAdmin(actorUserId: string, targetUserId: string) {
    await this.requireSuperAdmin(actorUserId);

    // Ensure target user exists
    const targetUser = await this.prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) throw new NotFoundException('Target user not found.');

    const superAdminRole = await this.prisma.adminRoleModel.findUnique({ where: { name: AdminRole.SUPER_ADMIN } });
    if (!superAdminRole) throw new NotFoundException('SUPER_ADMIN role definition not found.');

    await this.prisma.$transaction(async (tx) => {
      const membership = await tx.adminMembership.upsert({
        where: { userId: targetUserId },
        update: {
          roleId: superAdminRole.id,
          isActive: true,
        },
        create: {
          userId: targetUserId,
          roleId: superAdminRole.id,
          isActive: true,
        },
      });

      await this.auditService.log(actorUserId, 'ADMIN_ROLE_ASSIGNED', 'AdminMembership', membership.id, { role: 'SUPER_ADMIN' }, null, membership, tx);
    });

    return { message: 'Granted SUPER_ADMIN successfully.' };
  }

  /**
   * Demotes a SUPER_ADMIN. 
   * Safeguard against leaving zero SUPER_ADMINs.
   */
  async revokeSuperAdmin(actorUserId: string, targetUserId: string) {
    await this.requireSuperAdmin(actorUserId);

    // Transactionally protect the single-owner/last-admin invariant
    await this.prisma.$transaction(async (tx) => {
      // 1. Lock active SUPER_ADMIN memberships to count safely
      // In PostgreSQL, this requires a raw query to lock the rows
      const superAdminRole = await tx.adminRoleModel.findUnique({ where: { name: AdminRole.SUPER_ADMIN } });
      if (!superAdminRole) throw new NotFoundException('SUPER_ADMIN role definition not found.');

      await tx.$queryRaw`SELECT id FROM "AdminMembership" WHERE "roleId" = ${superAdminRole.id} AND "isActive" = true FOR UPDATE`;

      const activeSuperAdmins = await tx.adminMembership.count({
        where: {
          roleId: superAdminRole.id,
          isActive: true,
          user: { status: 'ACTIVE' }
        }
      });

      const targetMembership = await tx.adminMembership.findUnique({
        where: { userId: targetUserId },
      });

      if (!targetMembership || targetMembership.roleId !== superAdminRole.id || !targetMembership.isActive) {
        throw new BadRequestException('Target is not currently an active SUPER_ADMIN.');
      }

      if (activeSuperAdmins <= 1) {
        throw new ForbiddenException('Cannot remove the final active SUPER_ADMIN.');
      }

      const updated = await tx.adminMembership.update({
        where: { userId: targetUserId },
        data: { isActive: false },
      });

      await this.auditService.log(actorUserId, 'ADMIN_ROLE_REMOVED', 'AdminMembership', targetMembership.id, { role: 'SUPER_ADMIN' }, targetMembership, updated, tx);
    });

    return { message: 'Revoked SUPER_ADMIN successfully.' };
  }

  private async requireSuperAdmin(actorUserId: string) {
    const adminMembership = await this.prisma.adminMembership.findUnique({
      where: { userId: actorUserId },
      include: { role: true },
    });

    if (
      !adminMembership ||
      !adminMembership.isActive ||
      !adminMembership.role ||
      !adminMembership.role.isActive ||
      adminMembership.role.name !== AdminRole.SUPER_ADMIN
    ) {
      throw new ForbiddenException('Only an active SUPER_ADMIN can perform this operation.');
    }
  }

  async findAll(actorUserId: string, query: AdminRoleQueryDto) {
    const { page, limit, search, skip } = query;

    const where: any = {};
    if (search) {
      where.name = { contains: search, mode: 'insensitive' };
    }

    const [data, total] = await Promise.all([
      this.prisma.adminRoleModel.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: { _count: { select: { permissions: true, memberships: true } } },
      }),
      this.prisma.adminRoleModel.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }

  async findOne(actorUserId: string, roleId: string) {
    const role = await this.prisma.adminRoleModel.findUnique({
      where: { id: roleId },
      include: { permissions: true },
    });

    if (!role) throw new NotFoundException('Role not found');
    return role;
  }

  async createRole(actorUserId: string, dto: AdminCreateRoleDto) {
    const existing = await this.prisma.adminRoleModel.findUnique({
      // Wait, name is AdminRole enum in prisma. We must be careful if we allow custom roles, 
      // but the schema uses enum AdminRole! So we can only create if it's a valid enum value 
      // that isn't already created.
      where: { name: dto.name as AdminRole },
    });

    if (existing) {
      throw new ConflictException('Role already exists');
    }

    if (!Object.values(AdminRole).includes(dto.name as AdminRole)) {
      throw new BadRequestException('Invalid role name, must match AdminRole enum.');
    }

    return this.prisma.$transaction(async (tx) => {
      const role = await tx.adminRoleModel.create({
        data: {
          name: dto.name as AdminRole,
          description: dto.description,
          permissions: {
            create: dto.permissions.map(p => ({ action: p })),
          },
        },
        include: { permissions: true },
      });

      await this.auditService.log(actorUserId, 'ADMIN_ROLE_CREATED', 'AdminRoleModel', role.id, null, null, role, tx);
      return role;
    });
  }

  async updateRole(actorUserId: string, roleId: string, dto: AdminUpdateRoleDto) {
    const role = await this.prisma.adminRoleModel.findUnique({
      where: { id: roleId },
      include: { permissions: true },
    });

    if (!role) throw new NotFoundException('Role not found');

    if (role.name === AdminRole.SUPER_ADMIN || role.name === AdminRole.SUPPORT) {
      if (dto.permissions) {
        throw new BadRequestException('Cannot modify permissions of built-in protected roles.');
      }
      if (dto.isActive === false && role.name === AdminRole.SUPER_ADMIN) {
        throw new BadRequestException('Cannot deactivate the SUPER_ADMIN role.');
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const updateData: any = {};
      if (dto.description !== undefined) updateData.description = dto.description;
      if (dto.isActive !== undefined) updateData.isActive = dto.isActive;

      if (dto.permissions) {
        // Delete all old and recreate
        await tx.adminPermission.deleteMany({ where: { roleId } });
        updateData.permissions = {
          create: dto.permissions.map(p => ({ action: p })),
        };
      }

      const updated = await tx.adminRoleModel.update({
        where: { id: roleId },
        data: updateData,
        include: { permissions: true },
      });

      await this.auditService.log(actorUserId, 'ADMIN_ROLE_UPDATED', 'AdminRoleModel', role.id, null, role, updated, tx);
      return updated;
    });
  }
}
