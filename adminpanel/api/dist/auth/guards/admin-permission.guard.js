var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, ForbiddenException, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma.service.js';
import { UserStatus, AdminRole } from '@prisma/client';
export const REQUIRE_ADMIN_PERMISSION_KEY = 'requireAdminPermission';
export const RequireAdminPermission = (...permissions) => SetMetadata(REQUIRE_ADMIN_PERMISSION_KEY, permissions);
let AdminPermissionGuard = class AdminPermissionGuard {
    reflector;
    prisma;
    constructor(reflector, prisma) {
        this.reflector = reflector;
        this.prisma = prisma;
    }
    async canActivate(context) {
        const requiredPermissions = this.reflector.getAllAndOverride(REQUIRE_ADMIN_PERMISSION_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);
        if (!requiredPermissions || requiredPermissions.length === 0) {
            return true;
        }
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        if (!user || user.status !== UserStatus.ACTIVE) {
            return false;
        }
        const membership = await this.prisma.adminMembership.findUnique({
            where: { userId: user.id },
            include: {
                role: {
                    include: {
                        permissions: true,
                    }
                }
            }
        });
        if (!membership || !membership.isActive) {
            throw new ForbiddenException('Admin access required or membership is inactive.');
        }
        if (!membership.role || !membership.role.isActive) {
            throw new ForbiddenException('Admin role is missing or inactive.');
        }
        if (membership.role.name === AdminRole.SUPER_ADMIN || membership.role.name === 'SUPER_ADMIN') {
            return true;
        }
        const userPermissions = membership.role.permissions.map(p => p.action);
        if (userPermissions.includes('*') || userPermissions.includes('ALL')) {
            return true;
        }
        const hasAllPermissions = requiredPermissions.every(p => userPermissions.includes(p));
        if (!hasAllPermissions) {
            throw new ForbiddenException('You do not have the required admin permissions.');
        }
        return true;
    }
};
AdminPermissionGuard = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [Reflector, PrismaService])
], AdminPermissionGuard);
export { AdminPermissionGuard };
//# sourceMappingURL=admin-permission.guard.js.map