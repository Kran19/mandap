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
import { PrismaService } from '../prisma.service.js';
import { MembershipRole } from '@prisma/client';
let MembershipsService = class MembershipsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getMembers(organizationId) {
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
    async addMember(organizationId, dto) {
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
        }
        catch (error) {
            if (error.code === 'P2002') {
                throw new ConflictException('User is already a member of this organization.');
            }
            throw error;
        }
    }
    async updateMemberRole(organizationId, targetUserId, dto) {
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
    async removeMember(organizationId, targetUserId) {
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
    async transferOwnership(organizationId, currentOwnerId, newOwnerId) {
        if (currentOwnerId === newOwnerId) {
            throw new BadRequestException('You are already the owner.');
        }
        await this.prisma.$transaction(async (tx) => {
            await tx.$queryRaw `SELECT id FROM "OrganizationMember" WHERE "organizationId" = ${organizationId} AND "userId" = ${currentOwnerId} FOR UPDATE`;
            await tx.$queryRaw `SELECT id FROM "OrganizationMember" WHERE "organizationId" = ${organizationId} AND "userId" = ${newOwnerId} FOR UPDATE`;
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
    async leaveOrganization(organizationId, userId) {
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
};
MembershipsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], MembershipsService);
export { MembershipsService };
//# sourceMappingURL=memberships.service.js.map