var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../../auth/guards/admin-permission.guard.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { PrismaService } from '../../prisma.service.js';
let AdminController = class AdminController {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getMe(user) {
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
        return {
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            status: user.status,
            roles: membership ? [membership.role] : [],
        };
    }
};
__decorate([
    Get(),
    __param(0, CurrentUser()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getMe", null);
AdminController = __decorate([
    Controller('admin/me'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [PrismaService])
], AdminController);
export { AdminController };
//# sourceMappingURL=admin.controller.js.map