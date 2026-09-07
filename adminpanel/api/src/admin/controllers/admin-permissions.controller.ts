import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';

@Controller('admin/permissions')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminPermissionsController {
  
  @Get()
  @RequireAdminPermission(AdminPermissions.PERMISSIONS_READ)
  findAll() {
    return Object.values(AdminPermissions).map(action => ({ action }));
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.PERMISSIONS_READ)
  findOne(@Param('id') action: string) {
    if (Object.values(AdminPermissions).includes(action as AdminPermissions)) {
      return { action };
    }
    return null;
  }
}
