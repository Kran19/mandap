var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';
import { MembershipRole } from '@prisma/client';
let OrganizationsService = class OrganizationsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createOrganization(userId, dto) {
        const baseSlug = this.generateSlug(dto.name);
        let currentSlug = baseSlug;
        let counter = 1;
        while (true) {
            try {
                const result = await this.prisma.$transaction(async (tx) => {
                    const org = await tx.organization.create({
                        data: {
                            name: dto.name,
                            slug: currentSlug,
                        },
                    });
                    await tx.organizationMember.create({
                        data: {
                            organizationId: org.id,
                            userId: userId,
                            role: MembershipRole.OWNER,
                        },
                    });
                    return org;
                });
                return result;
            }
            catch (error) {
                if (error.code === 'P2002' && error.meta?.target?.includes('slug')) {
                    counter++;
                    currentSlug = `${baseSlug}-${counter}`;
                    if (counter > 10) {
                        throw new ConflictException('Unable to generate a unique organization slug. Please try a different name.');
                    }
                }
                else {
                    throw error;
                }
            }
        }
    }
    async getUserOrganizations(userId) {
        const memberships = await this.prisma.organizationMember.findMany({
            where: { userId },
            include: {
                organization: true,
            },
        });
        return memberships.map((m) => ({
            id: m.organization.id,
            name: m.organization.name,
            slug: m.organization.slug,
            status: m.organization.status,
            role: m.role,
        }));
    }
    async getOrganization(organizationId) {
        const org = await this.prisma.organization.findUnique({
            where: { id: organizationId },
        });
        if (!org) {
            throw new NotFoundException('Organization not found');
        }
        return {
            id: org.id,
            name: org.name,
            slug: org.slug,
            status: org.status,
        };
    }
    async updateOrganization(organizationId, dto) {
        const org = await this.prisma.organization.update({
            where: { id: organizationId },
            data: {
                name: dto.name,
            },
        });
        return {
            id: org.id,
            name: org.name,
            slug: org.slug,
            status: org.status,
        };
    }
    generateSlug(name) {
        return name
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/(^-|-$)+/g, '');
    }
};
OrganizationsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], OrganizationsService);
export { OrganizationsService };
//# sourceMappingURL=organizations.service.js.map