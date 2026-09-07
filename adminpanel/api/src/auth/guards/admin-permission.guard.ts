import { Injectable, CanActivate, ExecutionContext, ForbiddenException, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma.service.js';
import { UserStatus } from '@prisma/client';

export const REQUIRE_ADMIN_PERMISSION_KEY = 'requireAdminPermission';
export const RequireAdminPermission = (...permissions: string[]) => SetMetadata(REQUIRE_ADMIN_PERMISSION_KEY, permissions);

@Injectable()
export class AdminPermissionGuard implements CanActivate {
  constructor(private reflector: Reflector, private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(REQUIRE_ADMIN_PERMISSION_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true; // No permissions required
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user || user.status !== UserStatus.ACTIVE) {
      return false; // Not authenticated or user inactive
    }

    // Lookup admin membership -> role -> permissions
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

    const userPermissions = membership.role.permissions.map(p => p.action);
    
    // Check if the user has ALL required permissions for this route
    const hasAllPermissions = requiredPermissions.every(p => userPermissions.includes(p));
    
    if (!hasAllPermissions) {
      throw new ForbiddenException('You do not have the required admin permissions.');
    }

    return true;
  }
}
