var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma.service.js';
import { MembershipRole } from '@prisma/client';
import { SetMetadata } from '@nestjs/common';
export const REQUIRE_ORG_ROLE_KEY = 'requireOrgRole';
export const RequireOrgRole = (...roles) => SetMetadata(REQUIRE_ORG_ROLE_KEY, roles);
let OrgRoleGuard = class OrgRoleGuard {
    reflector;
    prisma;
    constructor(reflector, prisma) {
        this.reflector = reflector;
        this.prisma = prisma;
    }
    async canActivate(context) {
        const requiredRoles = this.reflector.getAllAndOverride(REQUIRE_ORG_ROLE_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        const organizationId = request.params.organizationId || request.params.orgId;
        if (!organizationId) {
            throw new ForbiddenException('Organization ID is missing in route parameters.');
        }
        if (!user) {
            return false;
        }
        const membership = await this.prisma.organizationMember.findUnique({
            where: {
                organizationId_userId: {
                    organizationId,
                    userId: user.id,
                },
            },
        });
        if (!membership) {
            console.log('OrgRoleGuard Debug:', { routeOrgId: organizationId, tokenUserId: user.id });
            throw new ForbiddenException('You are not a member of this organization.');
        }
        if (requiredRoles && requiredRoles.length > 0) {
            const roleHierarchy = {
                [MembershipRole.OWNER]: 3,
                [MembershipRole.EDITOR]: 2,
                [MembershipRole.VIEWER]: 1,
            };
            const userRoleLevel = roleHierarchy[membership.role];
            const hasRequiredRole = requiredRoles.some((requiredRole) => {
                return userRoleLevel >= roleHierarchy[requiredRole];
            });
            if (!hasRequiredRole) {
                throw new ForbiddenException('You do not have the required role in this organization.');
            }
        }
        request.organizationMember = membership;
        return true;
    }
};
OrgRoleGuard = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [Reflector, PrismaService])
], OrgRoleGuard);
export { OrgRoleGuard };
//# sourceMappingURL=org-role.guard.js.map