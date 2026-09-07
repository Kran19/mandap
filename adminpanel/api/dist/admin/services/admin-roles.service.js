var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, ForbiddenException, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminRole } from '@prisma/client';
import { AdminAuditService } from './admin-audit.service.js';
let AdminRolesService = class AdminRolesService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async grantSuperAdmin(actorUserId, targetUserId) {
        await this.requireSuperAdmin(actorUserId);
        const targetUser = await this.prisma.user.findUnique({ where: { id: targetUserId } });
        if (!targetUser)
            throw new NotFoundException('Target user not found.');
        const superAdminRole = await this.prisma.adminRoleModel.findUnique({ where: { name: AdminRole.SUPER_ADMIN } });
        if (!superAdminRole)
            throw new NotFoundException('SUPER_ADMIN role definition not found.');
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
    async revokeSuperAdmin(actorUserId, targetUserId) {
        await this.requireSuperAdmin(actorUserId);
        await this.prisma.$transaction(async (tx) => {
            const superAdminRole = await tx.adminRoleModel.findUnique({ where: { name: AdminRole.SUPER_ADMIN } });
            if (!superAdminRole)
                throw new NotFoundException('SUPER_ADMIN role definition not found.');
            await tx.$queryRaw `SELECT id FROM "AdminMembership" WHERE "roleId" = ${superAdminRole.id} AND "isActive" = true FOR UPDATE`;
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
    async requireSuperAdmin(actorUserId) {
        const adminMembership = await this.prisma.adminMembership.findUnique({
            where: { userId: actorUserId },
            include: { role: true },
        });
        if (!adminMembership ||
            !adminMembership.isActive ||
            !adminMembership.role ||
            !adminMembership.role.isActive ||
            adminMembership.role.name !== AdminRole.SUPER_ADMIN) {
            throw new ForbiddenException('Only an active SUPER_ADMIN can perform this operation.');
        }
    }
    async findAll(actorUserId, query) {
        const { page, limit, search, skip } = query;
        const where = {};
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
    async findOne(actorUserId, roleId) {
        const role = await this.prisma.adminRoleModel.findUnique({
            where: { id: roleId },
            include: { permissions: true },
        });
        if (!role)
            throw new NotFoundException('Role not found');
        return role;
    }
    async createRole(actorUserId, dto) {
        const existing = await this.prisma.adminRoleModel.findUnique({
            where: { name: dto.name },
        });
        if (existing) {
            throw new ConflictException('Role already exists');
        }
        if (!Object.values(AdminRole).includes(dto.name)) {
            throw new BadRequestException('Invalid role name, must match AdminRole enum.');
        }
        return this.prisma.$transaction(async (tx) => {
            const role = await tx.adminRoleModel.create({
                data: {
                    name: dto.name,
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
    async updateRole(actorUserId, roleId, dto) {
        const role = await this.prisma.adminRoleModel.findUnique({
            where: { id: roleId },
            include: { permissions: true },
        });
        if (!role)
            throw new NotFoundException('Role not found');
        if (role.name === AdminRole.SUPER_ADMIN || role.name === AdminRole.SUPPORT) {
            if (dto.permissions) {
                throw new BadRequestException('Cannot modify permissions of built-in protected roles.');
            }
            if (dto.isActive === false && role.name === AdminRole.SUPER_ADMIN) {
                throw new BadRequestException('Cannot deactivate the SUPER_ADMIN role.');
            }
        }
        return this.prisma.$transaction(async (tx) => {
            const updateData = {};
            if (dto.description !== undefined)
                updateData.description = dto.description;
            if (dto.isActive !== undefined)
                updateData.isActive = dto.isActive;
            if (dto.permissions) {
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
};
AdminRolesService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminRolesService);
export { AdminRolesService };
//# sourceMappingURL=admin-roles.service.js.map