import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma.service.js';
import { MembershipRole } from '@prisma/client';

import { SetMetadata } from '@nestjs/common';
export const REQUIRE_ORG_ROLE_KEY = 'requireOrgRole';
export const RequireOrgRole = (...roles: MembershipRole[]) => SetMetadata(REQUIRE_ORG_ROLE_KEY, roles);

@Injectable()
export class OrgRoleGuard implements CanActivate {
  constructor(private reflector: Reflector, private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<MembershipRole[]>(REQUIRE_ORG_ROLE_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    
    // Explicit contract: Look for organizationId in route parameters
    const organizationId = request.params.organizationId || request.params.orgId;
    
    if (!organizationId) {
      throw new ForbiddenException('Organization ID is missing in route parameters.');
    }

    if (!user) {
      return false; // Not authenticated
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

    // Attach membership to request for downstream use if needed
    request.organizationMember = membership;
    return true;
  }
}
