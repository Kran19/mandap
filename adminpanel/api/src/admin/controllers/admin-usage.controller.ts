import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminUsageService } from '../services/admin-usage.service.js';
import { AdminUsageQueryDto } from '../dto/admin-usage.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/usage')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminUsageController {
  constructor(private readonly usageService: AdminUsageService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.USAGE_READ)
  findAll(@CurrentUser() actor: any, @Query() query: AdminUsageQueryDto) {
    return this.usageService.findAll(actor.id, query);
  }

  @Get(':organizationId')
  @RequireAdminPermission(AdminPermissions.USAGE_READ)
  findByOrg(@CurrentUser() actor: any, @Param('organizationId') orgId: string, @Query() query: AdminUsageQueryDto) {
    return this.usageService.findAll(actor.id, { ...query, organizationId: orgId } as any);
  }
}
