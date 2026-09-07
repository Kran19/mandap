import { CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma.service.js';
import { MembershipRole } from '@prisma/client';
export declare const REQUIRE_ORG_ROLE_KEY = "requireOrgRole";
export declare const RequireOrgRole: (...roles: MembershipRole[]) => import("@nestjs/common").CustomDecorator<string>;
export declare class OrgRoleGuard implements CanActivate {
    private reflector;
    private prisma;
    constructor(reflector: Reflector, prisma: PrismaService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
