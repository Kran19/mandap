var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { MembershipRole } from '@prisma/client';
let AdminMembershipsService = class AdminMembershipsService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async findAll(actorId, orgId, query) {
        const { page, limit, role, userId, skip } = query;
        const where = { organizationId: orgId };
        if (role)
            where.role = role;
        if (userId)
            where.userId = userId;
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
    async addMember(actorId, orgId, dto) {
        if (dto.role === MembershipRole.OWNER) {
            throw new BadRequestException('Cannot assign OWNER role via generic membership API.');
        }
        const org = await this.prisma.organization.findUnique({ where: { id: orgId } });
        if (!org)
            throw new NotFoundException('Organization not found');
        const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
        if (!user)
            throw new NotFoundException('User not found');
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
            await this.auditService.log(actorId, 'MEMBERSHIP_ADDED', 'OrganizationMember', membership.id, { organizationId: orgId, role: dto.role }, null, membership, tx);
            return membership;
        });
    }
    async updateMemberRole(actorId, orgId, userId, dto) {
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
            await this.auditService.log(actorId, 'MEMBERSHIP_ROLE_CHANGED', 'OrganizationMember', membership.id, { organizationId: orgId }, { role: membership.role }, { role: updated.role }, tx);
            return updated;
        });
    }
    async removeMember(actorId, orgId, userId) {
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
            await this.auditService.log(actorId, 'MEMBERSHIP_REMOVED', 'OrganizationMember', membership.id, { organizationId: orgId }, membership, null, tx);
            return { success: true };
        });
    }
};
AdminMembershipsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminMembershipsService);
export { AdminMembershipsService };
//# sourceMappingURL=admin-memberships.service.js.map