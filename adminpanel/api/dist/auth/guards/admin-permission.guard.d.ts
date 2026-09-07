import { CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma.service.js';
export declare const REQUIRE_ADMIN_PERMISSION_KEY = "requireAdminPermission";
export declare const RequireAdminPermission: (...permissions: string[]) => import("@nestjs/common").CustomDecorator<string>;
export declare class AdminPermissionGuard implements CanActivate {
    private reflector;
    private prisma;
    constructor(reflector: Reflector, prisma: PrismaService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
