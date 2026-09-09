import { Controller, Get, Patch, Post, Body, UseGuards, BadRequestException, ConflictException } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../../auth/guards/admin-permission.guard.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from '../services/admin-audit.service.js';
import { AdminUpdateProfileDto, AdminChangePasswordDto } from '../dto/admin-profile.dto.js';
import { normalizePhone } from '../../utils/phone.util.js';
import * as argon2 from 'argon2';

@Controller('admin/me')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminController {
  constructor(
    private prisma: PrismaService,
    private auditService: AdminAuditService,
  ) {}

  @Get()
  async getMe(@CurrentUser() user: any) {
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

  @Patch('profile')
  async updateProfile(
    @CurrentUser() user: any,
    @Body() dto: AdminUpdateProfileDto,
  ) {
    const dataToUpdate: any = {};

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
      let normalizedPhone: string | null = null;
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

    await this.auditService.log(
      user.id,
      'ADMIN_PROFILE_UPDATED',
      'User',
      user.id,
      {
        before: { email: user.email, phone: user.phone, firstName: user.firstName, lastName: user.lastName },
        after: updatedUser,
      },
    );

    return updatedUser;
  }

  @Post('change-password')
  async changePassword(
    @CurrentUser() user: any,
    @Body() dto: AdminChangePasswordDto,
  ) {
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

    await this.auditService.log(
      user.id,
      'ADMIN_PASSWORD_CHANGED',
      'User',
      user.id,
      { updated: true },
    );

    return { success: true, message: 'Password updated successfully.' };
  }
}

