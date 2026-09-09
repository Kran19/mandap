var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { UserStatus } from '@prisma/client';
let AdminUsersService = class AdminUsersService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async findAll(query) {
        const { page, limit, status, search, skip } = query;
        const where = {};
        if (status)
            where.status = status;
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
    async findOne(id) {
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
    async updateUser(actorId, id, dto) {
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
            if (status !== UserStatus.ACTIVE) {
                await tx.refreshSession.updateMany({
                    where: { userId: id, revokedAt: null },
                    data: { revokedAt: new Date() },
                });
            }
            await this.auditService.log(actorId, 'USER_STATUS_CHANGED', 'User', id, null, { status: user.status }, { status }, tx);
            return updatedUser;
        });
    }
    async deleteUser(actorId, id) {
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
            await tx.trialClaim.deleteMany({ where: { userId: id } });
            await tx.trialSetup.deleteMany({ where: { userId: id } });
            await tx.order.updateMany({
                where: { userId: id },
                data: { userId: null },
            });
            await tx.refreshSession.deleteMany({ where: { userId: id } });
            const deletedUser = await tx.user.delete({
                where: { id },
            });
            await this.auditService.log(actorId, 'USER_DELETED', 'User', id, {
                deletedEmail: user.email,
                deletedName: `${user.firstName || ''} ${user.lastName || ''}`.trim(),
            }, {
                id: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                status: user.status,
            }, null, tx);
            return { success: true, id: deletedUser.id };
        });
    }
};
AdminUsersService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminUsersService);
export { AdminUsersService };
//# sourceMappingURL=admin-users.service.js.map