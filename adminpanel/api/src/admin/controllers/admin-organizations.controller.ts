import { Controller, Get, Param, UseGuards, Query, Patch, Body } from '@nestjs/common';
import { AdminOrganizationsService } from '../services/admin-organizations.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { AdminOrganizationQueryDto, AdminUpdateOrganizationDto } from '../dto/admin-organizations.dto.js';

@Controller('admin/organizations')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminOrganizationsController {
  constructor(private readonly adminOrganizationsService: AdminOrganizationsService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.ORGANIZATIONS_READ)
  findAll(@CurrentUser() user: any, @Query() query: AdminOrganizationQueryDto) {
    return this.adminOrganizationsService.findAll(user.id, query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.ORGANIZATIONS_READ)
  getOrganization(@CurrentUser() user: any, @Param('id') id: string) {
    return this.adminOrganizationsService.getOrganization(user.id, id);
  }

  @Patch(':id')
  @RequireAdminPermission(AdminPermissions.ORGANIZATIONS_WRITE)
  updateOrganization(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: AdminUpdateOrganizationDto,
  ) {
    return this.adminOrganizationsService.updateOrganization(user.id, id, dto);
  }
}
