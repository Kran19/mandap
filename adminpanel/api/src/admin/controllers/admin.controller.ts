import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../../auth/guards/admin-permission.guard.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { PrismaService } from '../../prisma.service.js';

@Controller('admin/me')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminController {
  constructor(private prisma: PrismaService) {}

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
      status: user.status,
      roles: membership ? [membership.role] : [],
    };
  }
}
