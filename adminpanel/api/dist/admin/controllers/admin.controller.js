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
import { Controller, Get, Patch, Post, Body, UseGuards, BadRequestException, ConflictException } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../../auth/guards/admin-permission.guard.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from '../services/admin-audit.service.js';
import { AdminUpdateProfileDto, AdminChangePasswordDto } from '../dto/admin-profile.dto.js';
import { normalizePhone } from '../../utils/phone.util.js';
import * as argon2 from 'argon2';
let AdminController = class AdminController {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
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
            phone: user.phone,
            status: user.status,
            roles: membership ? [membership.role] : [],
        };
    }
    async updateProfile(user, dto) {
        const dataToUpdate = {};
        if (dto.email !== undefined) {
            const email = dto.email.trim().toLowerCase();
            if (email && email !== user.email?.toLowerCase()) {
                const existing = await this.prisma.user.findUnique({ where: { email } });
                if (existing && existing.id !== user.id) {
                    throw new ConflictException('This email address is already in use.');
                }
            }
            dataToUpdate.email = email || null;
        }
        if (dto.phone !== undefined) {
            const phoneInput = dto.phone?.trim();
            let normalizedPhone = null;
            if (phoneInput) {
                normalizedPhone = normalizePhone(phoneInput);
                if (normalizedPhone !== user.phone) {
                    const existing = await this.prisma.user.findUnique({ where: { phone: normalizedPhone } });
                    if (existing && existing.id !== user.id) {
                        throw new ConflictException('This phone number is already in use.');
                    }
                }
            }
            dataToUpdate.phone = normalizedPhone;
        }
        if (dto.firstName !== undefined) {
            dataToUpdate.firstName = dto.firstName ? dto.firstName.trim() : null;
        }
        if (dto.lastName !== undefined) {
            dataToUpdate.lastName = dto.lastName ? dto.lastName.trim() : null;
        }
        const updatedUser = await this.prisma.user.update({
            where: { id: user.id },
            data: dataToUpdate,
            select: {
                id: true,
                email: true,
                firstName: true,
                lastName: true,
                phone: true,
                status: true,
            },
        });
        await this.auditService.log(user.id, 'ADMIN_PROFILE_UPDATED', 'User', user.id, {
            before: { email: user.email, phone: user.phone, firstName: user.firstName, lastName: user.lastName },
            after: updatedUser,
        });
        return updatedUser;
    }
    async changePassword(user, dto) {
        const dbUser = await this.prisma.user.findUnique({
            where: { id: user.id },
        });
        if (!dbUser) {
            throw new BadRequestException('User not found.');
        }
        const isMatch = await argon2.verify(dbUser.passwordHash, dto.currentPassword);
        if (!isMatch) {
            throw new BadRequestException('Current password is incorrect.');
        }
        if (dto.currentPassword === dto.newPassword) {
            throw new BadRequestException('New password must be different from current password.');
        }
        const passwordHash = await argon2.hash(dto.newPassword);
        await this.prisma.user.update({
            where: { id: user.id },
            data: { passwordHash },
        });
        await this.auditService.log(user.id, 'ADMIN_PASSWORD_CHANGED', 'User', user.id, { updated: true });
        return { success: true, message: 'Password updated successfully.' };
    }
};
__decorate([
    Get(),
    __param(0, CurrentUser()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getMe", null);
__decorate([
    Patch('profile'),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminUpdateProfileDto]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateProfile", null);
__decorate([
    Post('change-password'),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminChangePasswordDto]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "changePassword", null);
AdminController = __decorate([
    Controller('admin/me'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService])
], AdminController);
export { AdminController };
//# sourceMappingURL=admin.controller.js.map